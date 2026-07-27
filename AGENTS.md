# Agents

## Agent skills

### Issue tracker

GitHub issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical roles: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at repo root. See `docs/agents/domain.md`.

## Fix workflow

When fixing a bug, follow this exact sequence:

1. **Apply fix** — make the code change
2. **Test locally** — run `make test`, verify output
3. **Check output** — if satisfactory, proceed
4. **Raise issue** — document the bug (what we got, what we expected, what actually happened)
5. **Create branch** — `fix/<short-description>` from main
6. **Open PR** — link the issue, include test documentation

**Do not merge.** Merging is done by the maintainer.
