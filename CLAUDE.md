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

## Agent skills

### Issue tracker

Issues and PRDs live in `paradisec-archive/nabu` GitHub Issues (via the `gh` CLI). See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles mapped to default label names. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `CONTEXT.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

