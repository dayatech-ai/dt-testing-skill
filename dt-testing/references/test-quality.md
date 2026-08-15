# Test Quality

A passing test suite is not enough. Review whether tests are meaningful.

## Good tests

- assert observable behavior
- cover happy path and meaningful edge cases
- verify expected errors
- avoid duplicating implementation logic in assertions
- are deterministic
- have clear setup and intent
- fail for the right reason

## Avoid

- assertions such as `result != null` when stronger behavior can be checked
- testing framework internals
- excessive mocking
- mocking the code under test
- duplicated tests with no additional value
- implementation-detail coupling when behavior can be asserted instead
- changing production logic only to satisfy a mistaken test

## Bug fix rule

When practical:
1. write a test that reproduces the bug
2. confirm it fails
3. fix the code
4. confirm it passes
5. run the full project test suite using the completion requirements in `workflow.md`

The regression test can be unit, integration, or E2E depending on where the bug is observable.
