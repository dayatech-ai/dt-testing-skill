# DT-TESTING Adaptive Testing Skill — Compact Universal Version

A compact language-agnostic coding-agent skill for selecting and executing relevant:

- Unit tests (mandatory)
- Integration tests (mandatory)
- E2E tests (based on critical flows)
- Security tests (based on security risk)

`SKILL.md` is intentionally small to reduce prompt/token usage. Detailed rules live under `references/` and should be read only when needed.

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
