# Personal fork workflow

- `main` mirrors `eerimoq/moblin` — never commit to it.
- `custom` holds personal changes.

Pull in upstream changes:

```sh
git fetch upstream
git checkout main && git merge --ff-only upstream/main && git push origin main
git checkout custom && git rebase main
```

Local signing lives in `Config/User.xcconfig` (gitignored).
Build/test on Mac Catalyst or a real device only (see AGENTS.md).
