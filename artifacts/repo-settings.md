# Repository settings evidence

Date: 2026-10-29
Repository: `gorizond/koldun-gitops`

## Visibility

Public, consistent with the other `gorizond` repositories.

## Default branch

`main`

## Protection

Repository ruleset `protect-main` (id 26122050), enforcement `active`, `bypass_actors: []`,
`current_user_can_bypass: never`.

| Rule | Setting |
|---|---|
| pull_request | required, stale reviews dismissed, review threads resolved, 0 mandatory approvals |
| required_status_checks | `lint`, `secret-scan` (strict: branch must be up to date) |
| non_fast_forward | enabled |
| deletion | blocked |

Approvals are set to 0 because the repository has a single owner account and GitHub
does not allow self-approval. The review gate is the pull request plus the owner's merge.

## Negative control

Direct push to `main` was attempted and rejected:

```
remote: - Changes must be made through a pull request.
! [remote rejected] feat/phase-1-bootstrap -> main (push declined due to repository rule violations)
```

`main` stayed at the bootstrap commit `c105c1a`.

## Note

The first protection attempt used classic branch protection with
`required_approving_review_count: 0`. That configuration blocked force pushes but
allowed a regular fast-forward push, so it was replaced by a repository ruleset.
