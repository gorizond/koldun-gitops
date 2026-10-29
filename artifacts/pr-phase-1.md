# Phase 1 pull request evidence

Date: 2026-10-29
Pull request: https://github.com/gorizond/koldun-gitops/pull/1
Branch: `feat/phase-1-bootstrap` -> `main`

## Scope

Tasks T001-T007: repository bootstrap, CI gates, review requirements.
No cluster resources are created by this change.

## CI

| Check | Result |
|---|---|
| `lint` (yamllint, helm lint, english-only) | pass |
| `secret-scan` (gitleaks, default passwords) | pass |

## Notes

- The first run of `secret-scan` failed because the default-password pattern matched
  its own workflow file. The workflow directory is now excluded from that scan;
  layer manifests remain covered.
- The repository had no `main` branch when the first branch was pushed, so GitHub made
  the feature branch the default. The default branch is back to `main`.

## Merge gate

Merged only after the owner approves the pull request.
