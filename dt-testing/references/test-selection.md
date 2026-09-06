# Test Selection

## Unit test

Required. Validate behavior in isolation; reuse adequate existing coverage or add/update tests for the behavior in scope.

Typical triggers:
- business logic
- calculations
- validation
- transformation/parsing
- decision rules
- boundary conditions
- reusable functions/classes/modules

Prefer many fast unit tests for logic-heavy code.

## Integration test

Required. Validate actual components working together; reuse adequate existing coverage or add/update tests at a relevant boundary for the behavior in scope.

Typical boundaries:
- API/controller -> service
- service -> repository
- repository -> database
- module -> module
- service -> queue/cache/storage
- service -> external system

Prefer real dependencies when practical. Mock external systems only when they are expensive, unreliable, destructive, or outside the system boundary.

## E2E test

Frontend E2E is mandatory for every user-facing case in the task scope, not just critical journeys. For a whole-project testing task, inventory all frontend features; for a feature/change task, inventory all cases of the affected frontend behavior.

Build a case inventory from requirements and observable behavior: successful flows, validation failures, error/retry paths, navigation, relevant loading/empty states, permissions, and boundary cases. Map every applicable case to an existing or new browser E2E test. Include relevant role/state variations; do not interpret all cases as every possible input value or internal implementation branch.

Use Playwright for frontend E2E if the project has no E2E framework. Retain an existing framework that supports the required browser flows and project execution setup; missing test cases alone do not justify replacing it. Follow `stack-detection.md` when assessing the existing stack.

Run the application in a browser using the selected E2E stack. Assert user-visible outcomes through the complete flow and use actual application services in a controlled test environment where applicable. Component tests or fully mocked application flows alone do not satisfy E2E coverage. Reuse adequate existing tests and follow `test-quality.md`; unit and integration coverage does not waive the E2E requirement.

Missing cases or blocked browser/service setup remain unresolved requirements. Report them explicitly instead of declaring frontend E2E complete. Projects with no frontend have no frontend E2E requirement.

Backend E2E is optional. Add it when:
- a critical workflow spans multiple API calls
- integration tests do not sufficiently prove the full business flow
- system-level orchestration is important

For backend-only E2E, focus on high-value system flows; the frontend requirement above still covers all applicable user-facing cases.

## Security test

Required for every project. Read `security.md` and select meaningful cases from the project’s actual inputs, trust boundaries, and risks, prioritizing behavior introduced or affected by the change. Reuse adequate existing coverage or add/update missing tests.

Typical triggers:
- authentication
- authorization
- role/permission changes
- sensitive data
- file upload/download
- database queries
- user-controlled input
- admin/privileged operations
- secrets/tokens/session handling
- payment or high-impact actions

Security tests should verify denial behavior as well as allowed behavior.

## Selection principle

Select by observable behavior and risk, not by file count.

Unit, integration, and project-appropriate security coverage must all exist. Do not add duplicate or placeholder tests merely to satisfy the requirement. If a meaningful unit target, integration boundary, or security case cannot be identified, report the missing coverage and blocker; do not mark the requirement complete or invent production components solely for testing.

Examples:

Pure calculation change:
- Unit: required
- Integration: required at the calculation's consumer or module boundary
- Frontend E2E: required for all affected user-facing calculation cases when exposed in the frontend; not applicable to a backend-only/library change
- Security: required; test relevant numeric input limits or resource bounds at the exposed consumer boundary, based on actual project risks

New protected API endpoint:
- Unit: required for isolated behavior such as validation or decision rules
- Integration: required
- Frontend E2E: required for all affected UI cases if consumed by the frontend
- Backend E2E: optional depending on flow criticality
- Security: required
