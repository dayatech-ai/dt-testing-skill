# Stack Detection

The skill is language and framework agnostic.

Before implementing or running tests, inspect repository evidence.

## Detect from

- manifest/build files
- package manager files
- existing test directories/files
- CI configuration
- scripts/tasks
- project documentation
- nearby modules with tests

Examples of repository signals:
- Rust: `Cargo.toml`
- Python: `pyproject.toml`, `uv.lock`, `requirements*.txt`
- Node/TypeScript: `package.json`
- Go: `go.mod`
- Java/Kotlin: `pom.xml`, `build.gradle*`
- .NET: `*.csproj`, `*.sln`

These are examples only; do not assume the test framework from language alone.

## Priority order

1. existing project test commands
2. existing test framework and conventions
3. CI commands
4. framework/build-tool defaults

Do not introduce a new test framework when the repository already has an established stack unless explicitly requested or technically necessary.

For monorepos, detect the stack per affected package/service rather than assuming one global framework.
