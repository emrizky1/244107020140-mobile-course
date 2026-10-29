# Branch and commit hygiene review

## Audit

- The audit was run on `feat/notes-validation`; the working tree is clean and there are no untracked files.
- The history includes vague messages such as `week7`, `week 6`, and `AI challenge`. The visible history is linear and shared by `main` and `develop`, so the log alone cannot establish which commits were made directly on `main`.
- `main` and `develop` currently point to the October 15 `week7` commit, and `backup-local-work` points to September 14; all three tips are more than one week old. The feature branch has October 29 commits.
- `develop` already exists and tracks `origin/develop`. `feat/notes-validation` is based on it and tracks `origin/feat/notes-validation`; continue feature work on feature branches and use `develop` as the integration base.

## Commit message rewrites (simulation)

| Before | After | Reason |
| --- | --- | --- |
| `week7` | `feat(campus-notify): add app scaffold and core features` | Describes the new application scaffold and its feature scope instead of using a course-week label. |
| `week 6` | `feat(notifications): add push messaging and app routing` | Names the notification and routing work visible in the commit's push-service and route changes. |
| `remove google-services.json` | `chore(android): ignore Firebase configuration file` | Matches the actual change, which adds the config filename to `.gitignore` rather than deleting the file in this commit. |

These are proposed rewrites for the lab only; historical commits were not rewritten.
