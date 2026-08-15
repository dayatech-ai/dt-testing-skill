# Security Testing

Focus on security-sensitive behavior introduced or affected by the change.

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
