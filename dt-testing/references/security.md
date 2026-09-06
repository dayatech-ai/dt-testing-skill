# Security Testing

Security testing is mandatory and must follow `test-quality.md`. Tailor cases to the project rather than requiring every category below.

## Select coverage for the project

1. Inspect the stack, entry points, untrusted inputs, sensitive data, and trust boundaries. Prioritize security-sensitive behavior introduced or affected by the change.
2. Select concrete risks and assert the expected safe behavior. For APIs, consider access control and input handling; for frontends, unsafe rendering and sensitive data exposure; for CLI tools/installers, path traversal and command injection; for libraries/data processing, malformed inputs and resource limits where relevant.
3. Ensure meaningful security tests exist. Reuse adequate existing tests or add/update missing cases; security tests may be part of unit, integration, or E2E suites and do not require a separate runner or directory. A generic edge-case test counts only when it verifies an identified security risk.
4. Document selected risks, their tests, and why other categories do not apply. Do not invent authentication or other features absent from the project. If no meaningful security case can be identified or executed, report the coverage gap or execution blocker; do not silently waive the requirement or claim completion.

Run security tests with the full-suite requirements in `workflow.md`; a risk checklist or scanner run alone does not replace behavioral security tests.

## Authentication

Check:
- unauthenticated requests are rejected
- invalid/expired credentials fail safely
- authentication state cannot be bypassed

## Authorization

Check:
- users cannot access other users' protected resources
- lower-privilege roles cannot perform higher-privilege actions
- object-level authorization is enforced
- default-deny behavior where appropriate

## Input and injection

Check relevant untrusted inputs for:
- SQL/command/template injection
- path traversal
- unsafe file handling
- XSS where rendered content is involved
- malformed payloads and unexpected types

## Sensitive data

Check:
- secrets/passwords/tokens are not exposed in responses or logs
- restricted fields are not returned to unauthorized users
- sensitive operations require correct permissions

## Principle

Do not run broad destructive security attacks by default. Prefer targeted, safe, repository-appropriate tests around the changed security boundary.
