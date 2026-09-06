# DT-TESTING Adaptive Testing Skill — Compact Universal Version

A compact language-agnostic coding-agent skill for selecting and executing relevant:

- Unit tests (mandatory)
- Integration tests (mandatory)
- Frontend E2E tests (mandatory for all user-facing cases in scope)
- Backend E2E tests (optional when integration coverage is sufficient)
- Security tests (mandatory, tailored to project risks)

All test types must follow `references/test-quality.md`; read and apply it when designing, adding, updating, reusing, or auditing tests. Passing execution alone does not satisfy the quality review requirement.

`SKILL.md` is intentionally small to reduce prompt/token usage. Detailed rules live under `references/`; read mandatory references as instructed and other references when needed.

## Structure

```text
dt-testing/
├── SKILL.md
├── README.md
└── references/
    ├── workflow.md
    ├── test-selection.md
    ├── test-quality.md
    ├── security.md
    └── stack-detection.md
```

The skill supports new features, existing-feature test backfill, changes/bug fixes, and test audits.
