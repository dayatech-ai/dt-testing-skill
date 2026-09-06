# Workflow

## Task modes

Detect the mode from the request and repository state.

In every mode, read and apply `test-quality.md` before designing, adding, updating, reusing, or auditing any tests. Its quality criteria apply to every test type. When the scope includes frontend behavior, read `test-selection.md`, inventory all user-facing cases, and ensure each has browser E2E coverage in every mode.

### New feature

1. Understand expected behavior.
2. Implement the feature.
3. Plan mandatory unit, integration, and project-appropriate security coverage, plus mandatory E2E for all frontend cases in scope.
4. Add tests with the feature.
5. Follow the test execution and completion requirements below.
6. Review failures and test quality.

### Existing feature / test backfill

1. Inspect production behavior first.
2. Inspect existing tests.
3. Identify untested observable behavior and boundaries.
4. Ensure unit, integration, and project-appropriate security coverage all exist; add missing tests without inventing requirements.
5. Follow the test execution and completion requirements below.

### Change / bug fix

1. Inspect affected code and tests.
2. Identify impacted behavior.
3. For bugs, reproduce with a failing test when practical.
4. Implement the fix or change.
5. Update/add tests so unit, integration, and project-appropriate security coverage address the affected behavior.
6. Follow the test execution and completion requirements below.

### Test audit

1. Inspect existing tests and production code.
2. Check that unit, integration, and project-appropriate security tests all exist and cover the behavior in scope; identify missing critical coverage, weak assertions, duplication, and excessive mocking.
3. Prioritize gaps by business risk and change frequency.
4. Add or improve only high-value tests.
5. When tests are added or updated, follow the test execution and completion requirements below.

## Test execution and completion requirements

### Provide a way to run tests

1. Discover existing test commands, runner configuration, and CI suites. Reuse the established stack.
2. If no command runs all project tests, add an appropriate project script/task or documented native runner command. Ensure it discovers both existing and newly added tests, exits after one run, and returns a nonzero status on failure. An aggregate command must preserve failures from every suite.
3. Add or update the project's testing documentation in its existing README or testing guide. Include the working directory, dependency installation, required environment variables with safe example values, test services/setup and cleanup, and exact commands to run the full suite. Document focused commands when useful. If the command already exists but instructions are missing, document it.
4. For monorepos or multiple runners, cover every package/service with tests and every existing test suite, including integration and E2E suites that require separate commands. List those commands and prerequisites explicitly if a single entry point is impractical.

### Run and resolve

Review all tests added, updated, or relied on within the task scope against `test-quality.md`. Resolve quality issues within scope before the final full-suite run, and report any remaining quality gaps separately from execution results.

Before completion, confirm meaningful unit, integration, and project-appropriate security coverage all exist for the scope, and every frontend case in the inventory maps to an E2E test. Adequate existing tests satisfy this requirement without duplication. Missing coverage remains an unresolved requirement, even if the available suite passes. In a read-only audit, report missing coverage without editing files.

1. During implementation, targeted tests may provide faster feedback.
2. After completing test additions or updates, every agent must execute the full project suite using the documented commands. Selecting relevant test types controls which tests to add, not which existing suites to run.
3. Inspect failures, correct their causes within the task's authorized scope, then rerun the full suite after the final fix. Do not delete, skip, weaken assertions, suppress exit codes, or alter test discovery just to obtain a passing result.
4. If failures require unrelated changes, or execution is blocked by unavailable dependencies, services, credentials, or permissions, report the exact failing or blocked commands and what is needed to resolve them. Do not present incomplete verification as success.
5. Declare full-suite verification successful only when all required commands pass on the final project state. Report any skipped tests separately; an exit code of zero with skipped suites is not full verification. A successful build is not a substitute for running tests.

## Output expectation

Report:
- mandatory unit, integration, and project-appropriate security coverage, including reused tests and any gaps
- security risks tested, coverage locations, and rationale for inapplicable security categories
- frontend case inventory mapped to E2E tests, including reused coverage and missing cases
- backend E2E tests selected and why
- tests added/updated
- quality review against `test-quality.md`, including issues corrected and unresolved quality gaps
- test command/configuration and documentation added/updated, with file paths
- commands run
- full-suite pass/fail summary, including skipped tests and blocked suites
- frontend E2E applicability (no frontend in scope), or unresolved coverage/execution blockers
- optional backend E2E tests not added and rationale
- unresolved failures or prerequisites and their effect on completion
