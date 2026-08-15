"""Plan Conventional Commit releases and build minimal, reproducible assets."""
import argparse
import hashlib
import os
from pathlib import Path
import re
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def next_version(previous, messages):
    level = 0
    for message in messages:
        subject = message.splitlines()[0] if message else ""
        if re.match(r"^[a-z]+(?:\([^\n]+\))?!:", subject) or re.search(r"^BREAKING[ -]CHANGE:\s", message, re.M):
            level = max(level, 3)
        elif re.match(r"^feat(?:\([^\n]+\))?:", subject):
            level = max(level, 2)
        elif re.match(r"^(?:fix|perf)(?:\([^\n]+\))?:", subject):
            level = max(level, 1)
    major, minor, patch = previous
    if level == 3:
        return major + 1, 0, 0
    if level == 2:
        return major, minor + 1, 0
    if level == 1:
        return major, minor, patch + 1
    return None


def plan():
    tags = [tag for tag in git("tag", "--merged", "HEAD").splitlines()
            if re.fullmatch(r"v\d+\.\d+\.\d+", tag)]
    latest = max(tags, key=lambda t: tuple(map(int, t[1:].split(".")))) if tags else None
    # A tag at HEAD can be a draft from a failed publish; reruns finish that release.
    if latest and git("rev-list", "-n", "1", latest) == git("rev-parse", "HEAD"):
        return latest
    revision = latest + "..HEAD" if latest else "HEAD"
    messages = [m.strip() for m in git("log", "--format=%B%x00", revision).split("\0") if m.strip()]
    previous = tuple(map(int, latest[1:].split("."))) if latest else (0, 0, 0)
    version = next_version(previous, messages)
    return "v" + ".".join(map(str, version)) if version else ""


def build(tag, output, repo=None):
    repo = repo or os.environ.get("GITHUB_REPOSITORY", "")
    if repo and not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", repo):
        raise ValueError("Repository must be OWNER/REPO")
    if not re.fullmatch(r"v\d+\.\d+\.\d+", tag):
        raise ValueError("Expected vMAJOR.MINOR.PATCH")
    output.mkdir(parents=True, exist_ok=True)
    source = ROOT / "dt-testing"
    files = [source / "SKILL.md", *sorted((source / "references").glob("*.md"))]
    with zipfile.ZipFile(output / "dt-testing.zip", "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in files:
            info = zipfile.ZipInfo("dt-testing/" + path.relative_to(source).as_posix())
            info.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(info, path.read_bytes())
        archive.writestr("dt-testing/VERSION", tag[1:] + "\n")
    # Keep each standalone installer small as the project grows.
    for installer in ("install.sh", "install.ps1"):
        content = (ROOT / "scripts" / installer).read_text()
        if repo:
            content = content.replace("__DT_RELEASE_REPO__", repo)
        (output / installer).write_text(content)
        if (output / installer).stat().st_size > 16 * 1024:
            raise ValueError(f"{installer} exceeds the 16 KiB size budget")
    if (output / "dt-testing.zip").stat().st_size > 128 * 1024:
        raise ValueError("Skill package exceeds the 128 KiB size budget")
    lines = [hashlib.sha256((output / name).read_bytes()).hexdigest() + "  " + name
             for name in ("dt-testing.zip", "install.sh", "install.ps1")]
    (output / "SHA256SUMS").write_text("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--build", metavar="TAG")
    parser.add_argument("--output", type=Path, default=ROOT / "dist")
    args = parser.parse_args()
    if args.build:
        build(args.build, args.output)
    else:
        tag = plan()
        print(tag or "No releasable commits")
        if os.environ.get("GITHUB_OUTPUT"):
            with open(os.environ["GITHUB_OUTPUT"], "a") as stream:
                stream.write(f"tag={tag}\n")


if __name__ == "__main__":
    main()
