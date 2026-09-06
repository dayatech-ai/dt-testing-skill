---
name: dt-testing
description: Adaptive, language-agnostic testing for new features, existing code, bug fixes, and test audits. Requires unit, integration, and project-appropriate security tests, and frontend E2E for all user-facing cases in scope.
---

# Adaptive Testing

Use this skill after production-code changes or when tests are requested.

## Core rules

1. Inspect the repository before choosing tools or frameworks.
2. Reuse the existing test stack and conventions when available. For frontend E2E, use Playwright if no E2E framework exists; retain an existing framework that adequately supports the required scenarios.
3. Unit tests and integration tests are mandatory. Ensure both exist and cover the behavior in scope; add or update missing coverage and reuse adequate existing tests.
4. Security testing is mandatory; read `references/security.md` and tailor coverage to the project’s stack, inputs, trust boundaries, and risks. Security cases may live in unit or integration suites when they exercise real security behavior.
5. Frontend E2E is mandatory for all user-facing cases in scope, including success, validation, errors, and relevant edge cases. Read `references/test-selection.md` to inventory cases and map coverage. Unit and integration tests do not replace frontend E2E. Backend E2E is optional when integration coverage is sufficient.
6. For bug fixes, prefer a failing regression test before the fix when practical.
7. Do not change production behavior only to satisfy an incorrect test.
8. After adding or updating tests, every agent must run the full project test suite, including existing tests, before declaring completion. Targeted runs alone are insufficient.
9. Ensure the project has a documented, reproducible way to run all tests. If missing, add an appropriate test command and usage instructions using the existing stack.
10. Resolve test failures and rerun the full suite after fixes. Never claim all tests pass when any suite failed, was skipped, or could not run; report unresolved blockers explicitly.
11. Always read and apply `references/test-quality.md` when designing, adding, updating, reusing, or auditing tests. Its quality criteria are mandatory for every test type, including unit, integration, E2E, and security. Review test quality before completion; passing execution alone is insufficient.

## References

Read only what is needed:

- `references/workflow.md` — task modes, required test execution setup, full-suite verification, and reporting; always read when adding or updating tests
- `references/test-selection.md` — when to use unit, integration, E2E, security
- `references/test-quality.md` — mandatory quality criteria for all tests; always read when designing, adding, updating, reusing, or auditing tests
- `references/security.md` — mandatory security coverage and project-specific selection; always read when planning or reviewing tests
- `references/stack-detection.md` — language/framework/test-stack discovery
