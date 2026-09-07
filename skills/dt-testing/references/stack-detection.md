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

For frontend E2E, use Playwright when no E2E framework exists. An existing unit or component test runner alone is not an E2E framework. Retain an existing E2E framework if it supports the required browser flows and project execution setup. If it cannot, document the concrete technical limitation before selecting a replacement; missing coverage alone is not a framework limitation.

For monorepos, detect the stack per affected package/service rather than assuming one global framework.
