# Test Selection

## Unit test

Use when behavior can be validated in isolation.

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

Use when correctness depends on components working together.

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

Use when changes affect security boundaries or untrusted input.

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

Examples:

Pure calculation change:
- Unit: required
- Integration: usually not needed
- E2E: not needed
- Security: not needed

New protected API endpoint:
- Unit: if business logic exists
- Integration: required
- E2E: optional depending on flow criticality
- Security: required
