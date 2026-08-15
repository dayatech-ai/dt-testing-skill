---
name: dt-testing
description: Adaptive, language-agnostic testing for new features, existing code, bug fixes, and test audits. Selects relevant unit, integration, E2E, and security tests from repository context.
---

# Adaptive Testing

Use this skill after production-code changes or when tests are requested.

## Core rules

1. Inspect the repository before choosing tools or frameworks.
2. Reuse the existing test stack and conventions when available.
3. Select tests based on changed behavior, boundaries, risk, and critical flows.
4. Do not require every change to have every test type.
5. Backend E2E is optional when integration coverage is sufficient.
6. For bug fixes, prefer a failing regression test before the fix when practical.
7. Do not change production behavior only to satisfy an incorrect test.
8. After adding or updating tests, every agent must run the full project test suite, including existing tests, before declaring completion. Targeted runs alone are insufficient.
9. Ensure the project has a documented, reproducible way to run all tests. If missing, add an appropriate test command and usage instructions using the existing stack.
10. Resolve test failures and rerun the full suite after fixes. Never claim all tests pass when any suite failed, was skipped, or could not run; report unresolved blockers explicitly.

## References

Read only what is needed:

- `references/workflow.md` — task modes, required test execution setup, full-suite verification, and reporting; always read when adding or updating tests
- `references/test-selection.md` — when to use unit, integration, E2E, security
- `references/test-quality.md` — test quality and review rules
- `references/security.md` — security test guidance
- `references/stack-detection.md` — language/framework/test-stack discovery
