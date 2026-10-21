# CI/CD documentation

Start with the [owner cheat sheet](../../CICD-README.md): preparation,
dev → main squash, four commands, retries, common build counter and CLI setup.

- [Release runbook](RELEASE_RUNBOOK.md): verification and recovery, no manual tags.
- [Apple CI diagnostics](IOS_CI_DIAGNOSTICS.md): manual GET-only workflow, codes and +20/+21 recovery.
- [CLI contract and tests](../../tool/release/README.md).
- [One-time account setup](MANUAL_SETUP.md), [owner checklist](OWNER_CHECKLIST.md),
  [Android details](ANDROID_SETUP.md), [iOS native locks](IOS_DEPENDENCIES.md).
- [Apple Export Compliance decision](APPLE_EXPORT_COMPLIANCE.md): territory/SDK limits.
- [Lean CLI verification](LEAN_RELEASE_CLI.md).
- Dated evidence, not current commands: [plan](PLAN.md), [preflight](PREFLIGHT.md),
  [verification](VERIFICATION.md), [U4-B 1.2.3 preparation](RC_1.2.3_PREPARATION.md).

No document authorizes tags, builds or production. Owner gates and live store
checks remain mandatory; previous PASS results do not prove today's store state.
