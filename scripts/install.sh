#!/usr/bin/env bash
# Small standalone installer for macOS, Linux, and Windows through WSL/Git Bash.
set -euo pipefail
fail() { printf 'Installation failed: %s\n' "$*" >&2; exit 1; }
usage() {
  cat <<'EOF'
Usage: bash install.sh [--agent NAME] [--project DIR | --global] [options]
Without --agent: detect agents, install globally by default, and update automatically.
Agents: claude-code, antigravity, opencode, codex, all
Options:
  --repo OWNER/REPO       Download from a public GitHub Release (otherwise local source)
  --version VERSION       latest (default), or vMAJOR.MINOR.PATCH
  --skill NAME[,NAME...]  Install only the named skill(s) (default: all)
  --update                Back up and replace existing installations
  --dry-run               Preview without changing installed files
  --help                  Show usage
EOF
}
agent= repo='__DT_RELEASE_REPO__' root= scope= version=latest update=false dry_run=false skill_arg=
[[ "$repo" != '__DT_'"RELEASE_REPO__" ]] || repo=
while (($#)); do
  case "$1" in
    --agent|--repo|--project|--version|--skill)
      (($# >= 2)) && [[ -n "$2" && "$2" != --* ]] || fail "Missing value for $1"
      case "$1" in
        --agent) agent=$2 ;; --repo) repo=$2 ;; --version) version=$2 ;; --skill) skill_arg=$2 ;;
        --project) [[ -z "$scope" ]] || fail 'Choose one scope'; scope=project; root=$2 ;;
      esac
      shift 2 ;;
    --global) [[ -z "$scope" ]] || fail 'Choose one scope'; scope=global; root=$HOME; shift ;;
    --update) update=true; shift ;; --dry-run) dry_run=true; shift ;;
    --help|-h) usage; exit 0 ;; *) fail "Unknown argument: $1" ;;
  esac
done
automatic=false
if [[ -z "$scope" ]]; then scope=global; root=$HOME; fi
agents=()
if [[ -z "$agent" ]]; then
  automatic=true; update=true
  if command -v claude >/dev/null || [[ -d "$HOME/.claude" ]]; then agents+=(claude-code); fi
  if command -v antigravity >/dev/null || command -v agy >/dev/null || [[ -d "$HOME/.gemini/antigravity" || -d "$HOME/.gemini/config" ]]; then agents+=(antigravity); fi
  if command -v opencode >/dev/null || [[ -d "$HOME/.config/opencode" ]]; then agents+=(opencode); fi
  if command -v codex >/dev/null || [[ -d "$HOME/.codex" ]]; then agents+=(codex); fi
  if ((${#agents[@]} == 0)); then
    printf 'No agent detected. Choose claude-code, antigravity, opencode, codex, or all: ' >&2
    if ! { read -r agent < /dev/tty; } 2>/dev/null; then fail 'Use --agent NAME when no interactive terminal is available'; fi
  else
    printf 'Detected agents: %s\n' "${agents[*]}"
    agent=${agents[0]}
  fi
fi
case "$agent" in claude-code|antigravity|opencode|codex|all) ;; *) fail 'Choose --agent (see --help)' ;; esac
[[ -n "$scope" && -d "$root" ]] || fail 'Choose --global or --project with an existing directory'
root=$(cd -- "$root" && pwd -P)
[[ "$version" == latest || "$version" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Invalid version'
[[ -n "$repo" || "$version" == latest ]] || fail '--version requires --repo'
paths=()
if ((${#agents[@]} == 0)); then agents=("$agent"); fi
for selected_agent in "${agents[@]}"; do
  case "$selected_agent" in
    all) candidates=(.claude/skills .agents/skills .opencode/skills)
         [[ "$scope" != global ]] || candidates=(.claude/skills .gemini/config/skills .config/opencode/skills .agents/skills) ;;
    claude-code) candidates=(.claude/skills) ;;
    antigravity) candidates=(.agents/skills); [[ "$scope" != global ]] || candidates=(.gemini/config/skills) ;;
    opencode) candidates=(.opencode/skills); [[ "$scope" != global ]] || candidates=(.config/opencode/skills) ;;
    codex) candidates=(.agents/skills) ;;
  esac
  for candidate in "${candidates[@]}"; do
    duplicate=false
    for existing_path in "${paths[@]+"${paths[@]}"}"; do [[ "$existing_path" != "$candidate" ]] || duplicate=true; done
    [[ "$duplicate" == true ]] || paths+=("$candidate")
  done
done
work= stage=
cleanup() {
  [[ -z "$stage" ]] || rm -rf -- "$stage"
  [[ -z "$work" ]] || rm -rf -- "$work"
  return 0
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
discovered=()
if [[ -n "$repo" ]]; then
  [[ "$repo" =~ ^[a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+$ ]] || fail '--repo must be OWNER/REPO'
  for tool in curl unzip; do command -v "$tool" >/dev/null || fail "Required command: $tool"; done
  if command -v sha256sum >/dev/null; then hash=(sha256sum)
  elif command -v shasum >/dev/null; then hash=(shasum -a 256)
  else fail 'Required command: sha256sum or shasum'; fi
  work=$(mktemp -d)
  if [[ "$version" == latest ]]; then
    url=$(curl -fsSL --connect-timeout 15 --max-time 60 -o /dev/null -w '%{url_effective}' "https://github.com/$repo/releases/latest")
    prefix=https://github.com/$repo/releases/tag/
    [[ "$url" == "$prefix"* ]] || fail 'Could not resolve latest release'
    version=${url#"$prefix"}
  fi
  tag=v${version#v}
  [[ "$tag" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail 'Expected a stable release tag'
  base=https://github.com/$repo/releases/download/$tag
  for asset in skills.zip SHA256SUMS; do
    curl -fsSL --connect-timeout 15 --max-time 60 --max-filesize 2000000 "$base/$asset" -o "$work/$asset"
  done
  expected=$(awk '$2 == "skills.zip" {print $1}' "$work/SHA256SUMS")
  actual=$("${hash[@]}" "$work/skills.zip")
  [[ "$expected" =~ ^[a-fA-F0-9]{64}$ && "${actual%% *}" == "$expected" ]] || fail 'Release checksum mismatch'
  unzip -Z1 "$work/skills.zip" > "$work/files"
  # Allow only package files, one top-level directory per skill. Stream contents
  # into regular files, never restore ZIP symlinks.
  while IFS= read -r file; do
    [[ "$file" =~ ^([a-zA-Z0-9_-]+)/(SKILL\.md|VERSION|references/[a-zA-Z0-9_-]+\.md)$ ]] || fail "Unsafe release archive path: $file"
    name=${BASH_REMATCH[1]}
    known=false
    for existing_name in "${discovered[@]+"${discovered[@]}"}"; do [[ "$existing_name" != "$name" ]] || known=true; done
    [[ "$known" == true ]] || discovered+=("$name")
  done < "$work/files"
  ((${#discovered[@]})) || fail 'Release archive contains no skills'
  for name in "${discovered[@]}"; do mkdir -p "$work/$name/references"; done
  while IFS= read -r file; do
    unzip -p "$work/skills.zip" "$file" > "$work/$file"
  done < "$work/files"
  source=$work
  for name in "${discovered[@]}"; do
    [[ -f "$source/$name/VERSION" && "$(cat "$source/$name/VERSION")" == "${tag#v}" ]] || fail 'Package version does not match release tag'
    printf '{"repo":"%s","version":"%s"}\n' "$repo" "$tag" > "$source/$name/.release.json"
  done
else
  source=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)/skills
  for entry in "$source"/*/; do
    name=$(basename "$entry")
    [[ -f "$entry/SKILL.md" ]] && discovered+=("$name")
  done
  ((${#discovered[@]})) || fail "No skills found in source: $source"
fi
requested=()
if [[ -n "$skill_arg" ]]; then
  IFS=',' read -ra requested <<< "$skill_arg"
  for name in "${requested[@]}"; do
    match=false
    for candidate_skill in "${discovered[@]}"; do [[ "$candidate_skill" != "$name" ]] || match=true; done
    [[ "$match" == true ]] || fail "Unknown skill: $name"
  done
else
  requested=("${discovered[@]}")
fi
for path in "${paths[@]}"; do
  for name in "${requested[@]}"; do
    target=$root/$path/$name
    [[ ! -L "$target" ]] || fail "Refusing symlink destination: $target"
    if [[ -e "$target" ]]; then
      [[ "$update" == true && -d "$target" ]] || fail "Destination exists: $target (use --update)"
    fi
  done
done
for path in "${paths[@]}"; do
  for name in "${requested[@]}"; do
    parent=$root/$path
    target=$parent/$name
    if [[ "$automatic" == true && -n "$repo" && -f "$target/.release.json" && -f "$target/SKILL.md" && -f "$target/VERSION" ]]; then
      if [[ "$(cat "$target/VERSION")" == "${tag#v}" ]] && cmp -s "$source/$name/.release.json" "$target/.release.json"; then
        printf 'Already up to date: %s (%s)\n' "$target" "$tag"; continue
      fi
    fi
    if [[ "$dry_run" == true ]]; then printf 'Would install: %s\n' "$target"; continue; fi
    mkdir -p "$parent"
    stage=$(mktemp -d "$parent/.$name-XXXXXX")
    cp -R "$source/$name" "$stage/$name"
    backup=
    if [[ -d "$target" ]]; then
      mkdir -p "$parent/../skill-backups"
      backup=$(mktemp -d "$parent/../skill-backups/$name-XXXXXX")/$name
      mv "$target" "$backup"
    fi
    if ! mv "$stage/$name" "$target"; then
      if [[ -n "$backup" ]]; then mv "$backup" "$target" || fail "Restore failed; recover from $backup"; fi
      fail "Could not replace $target"
    fi
    [[ -z "$backup" ]] || printf 'Backup: %s\n' "$backup"
    rmdir "$stage"; stage=
    printf 'Installed: %s\n' "$target"
  done
done
