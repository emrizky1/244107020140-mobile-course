# Branch and commit hygiene review

## Audit

- The initial checkout was on `main`, with a clean working tree. No untracked files needed committing or ignoring.
- The history contains vague messages such as `week7`, `week 6`, and `AI challenge`; these do not explain the change or its scope.
- Commits dated September 24 and earlier are more than one week old. The `backup-local-work` branch also points to a September 14 commit and is stale.
- Only `main` existed on the remote at audit time, so `develop` was created from the current `main` tip and pushed. Continue feature work on `feat/*` branches from `develop`.

## Commit message rewrites (simulation)

| Before | After | Reason |
| --- | --- | --- |
| `week7` | `feat(notes): add local notes feature` | Names the feature and scope instead of using a course-week label. |
| `week 6` | `feat(auth): add login flow` | Identifies the authentication behavior and gives the change a conventional type. |
| `fix readme` | `docs(readme): clarify project setup` | Uses the documentation type and explains what was clarified. |

These are examples for the lab only; historical commits were not rewritten.
