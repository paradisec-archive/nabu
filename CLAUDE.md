# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Code Style Guidelines

- Use single quotes for strings unless interpolation is needed
- Follow Ruby/Rails conventions (Rubocop Rails Omakase with customizations)
- Never create blank lines with leading whitespace
- Maximum line length: 160 characters
- Prefer HAML for templates over ERB
- Use meaningful variable and method names
- Add proper error handling with appropriate logging
- Models should use validations when appropriate
- Follow REST conventions for controllers
- GraphQL mutations should inherit from BaseMutation

## Running Commands

This is a dockerized Rails application. Use `nabu_run` to execute Rails commands:

```bash
nabu_run bin/rails server
nabu_run bin/rails runner "puts User.count"
nabu_run bundle exec rubocop
```

## Running tests

- Run tests with `nabu_run bin/test [paths]`. It prepares the test databases first. With no paths it runs the full suite in parallel;
  pass paths while iterating.
- Each worktree automatically gets its own test databases, search indices and catalogue bucket. Never call `docker compose` directly,
  and never invent database or index names.
- `bin/test_prune` (on the host, not via `nabu_run`) lists test databases, indices and buckets left by removed worktrees; `--delete` drops them.
  Only run it by hand.

## Agent skills

### Issue tracker

Issues and PRDs live in `paradisec-archive/nabu` GitHub Issues (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles mapped to default label names. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

