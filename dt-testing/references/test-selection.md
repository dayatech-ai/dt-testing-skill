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

Use for critical end-to-end business or user flows.

Frontend E2E is recommended for critical user journeys.

Backend E2E is optional. Add it when:
- a critical workflow spans multiple API calls
- integration tests do not sufficiently prove the full business flow
- system-level orchestration is important

Avoid E2E for every branch or validation case; keep E2E coverage small and high-value.

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
- E2E: not needed
- Security: required; test relevant numeric input limits or resource bounds at the exposed consumer boundary, based on actual project risks

New protected API endpoint:
- Unit: required for isolated behavior such as validation or decision rules
- Integration: required
- E2E: optional depending on flow criticality
- Security: required
