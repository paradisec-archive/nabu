# Runbook — Permissions Phase 1 production deploy

Tracking issue: [#1135](https://github.com/paradisec-archive/nabu/issues/1135) ·
Parent: [#1127](https://github.com/paradisec-archive/nabu/issues/1127)

Coordinates the single production deploy for the Phase 1 permissions rework
(separating *attribution* from *access*). The user base is small and a brief
lockout window is acceptable, but **the steps must run in order** and the
contamination report **must be reviewed by a human** before any cleanup runs.

This is a `ready-for-human` task: every step below runs against production and
must be executed by a person with `nabu-prod` AWS credentials.

## What ships in this deploy

All of the following are already merged on the deploy branch and ship together
in a single `bin/release prod`:

| Issue | Change |
| ----- | ------ |
| #1128 | Ability: attribution (collector/operator) no longer confers rights |
| #1129 | Collection read-only grant via new `collection_users` membership |
| #1130 | Admin-only grant assignment on collection and item forms |
| #1131 | Contact-grant invariant (reject contact-only users from grants) |
| #1132 | `Permissions::CollectorBackfill` service + `permissions:collector_backfill` |
| #1133 | `Permissions::ContactGrantAuditor` + `permissions:contact_grants_*` tasks |
| #1134 | Collection deletion cleans up membership rows and grants |
| #1136 | DB-level `on_delete: :cascade` FKs on membership tables |

### Deploy-model caveat — migrations are NOT applied automatically

`bin/docker-entrypoint` is the `ENTRYPOINT` for the production container, but its
`db:prepare` branch only fires when the launch command ends with exactly
`./bin/rails server`. The production `CMD`
(`./bin/thrust ./bin/rails server --log-to-stdout -b 0.0.0.0`) ends in
`-b 0.0.0.0`, so the guard does **not** match and **no migration runs on boot**.

Migrations must therefore be run **explicitly** after deploy:

```bash
bin/aws/ecs_rake app db:migrate
```

(The README mentions `deploy:migrate`, but no such task is defined in this repo —
use `db:migrate`.)

This has an ordering consequence: `bin/release prod` rolls the new image into the
ECS service *before* you can migrate, so for a short window the new
Ability/membership code runs against the old schema (no `collection_users`).
Migrate as the very next step, immediately after the service is up. The banner
covers this window.

### The lockout window

Once #1128 is live, attribution stops conferring rights. Real collectors who
relied on being a collection/item's collector lose access until
`permissions:collector_backfill` (#1132) inserts their read-only grants. The
backfill needs `collection_users`, so it can only run after `db:migrate`. The gap
between deploy and a completed backfill is the acceptable lockout window — keep it
short by running migrate then backfill immediately once the deploy is healthy.

## Pre-flight

- [ ] Confirm the deploy branch is merged to `main` and CI is green.
- [ ] Confirm you can authenticate: `AWS_PROFILE=nabu-prod aws sts get-caller-identity`.
- [ ] Take/verify a recent production DB backup (`AWS_PROFILE=nabu-prod bin/aws/db_backup`).
- [ ] Dry-run the figures on staging if possible (deploy to stage, run the
      backfill and the contamination report there first).

## Steps

All rake tasks run on the production ECS task via `bin/aws/ecs_rake app <task>`.
For interactive work use `bin/aws/ecs_shell`.

### 1. Raise the announcement banner

The banner is data-driven via the `AdminMessage` model (served to the `oni`
frontend through the API, shown while `start_at <= now <= finish_at`). Create
one in ActiveAdmin (Admin → Admin Messages) **before** deploying, e.g.:

> PARADISEC is performing a brief permissions upgrade. Access may be
> intermittent for a short period. Thanks for your patience.

Set `start_at` to now and `finish_at` to a safe upper bound (e.g. +2 hours).

- [ ] Banner created and visible on the catalogue front end.

### 2. Deploy the code

```bash
bin/release prod
```

This ships the new image and rolls the ECS service. Migrations do **not** run
automatically (see caveat above).

- [ ] Deploy completed; service healthy.

### 2a. Apply the migration — *immediately after the service is up*

```bash
bin/aws/ecs_rake app db:migrate
```

- [ ] Migration applied; `collection_users` present in production
      (`bin/aws/ecs_rake app db:version`, or check via `bin/aws/ecs_shell`).

### 3. Run the collector backfill — *immediately after migrate*

```bash
bin/aws/ecs_rake app permissions:collector_backfill
```

Idempotent; targets only real, logged-in collectors (`contact_only = false`,
non-null `last_sign_in_at`); suppresses reindex callbacks. **Record the printed
counts** (collection read-only / item read-only inserted) in the issue and
confirm they match the expected production divergence figures.

- [ ] Backfill run; inserted counts recorded and confirmed.

### 4. Contamination report → **human review** → cleanup

First, report only (read-only, no mutation):

```bash
bin/aws/ecs_rake app permissions:contact_grants_report
```

- [ ] **A human reviews the contamination and orphan counts before proceeding.**
      Do not run cleanup until the figures look sane.

Then delete contaminated grants (grants pointing at contact-only users):

```bash
bin/aws/ecs_rake app permissions:contact_grants_cleanup
```

Finally, prune orphan grants (grants pointing at deleted items/collections) as a
**separate, explicit, confirmed step**:

```bash
bin/aws/ecs_rake app permissions:contact_grants_cleanup PRUNE_ORPHANS=true
```

- [ ] Report reviewed by a human.
- [ ] Contact cleanup run; deleted counts recorded.
- [ ] Orphan prune run as its own confirmed step; deleted counts recorded.

### 5. Single explicit bulk reindex

The backfill and cleanup steps suppress Searchkick callbacks, so search must be
rebuilt once, explicitly:

```bash
bin/aws/ecs_rake app search:reindex
```

Reindexes Collection, Item, and Essence (size-aware batching for Essence).

- [ ] Bulk reindex of collections, items, essences completed.

### 6. Lower the announcement banner

Expire the `AdminMessage` (set `finish_at` to now, or delete the record) in
ActiveAdmin.

- [ ] Banner removed.

## Post-deploy verification (spot-check)

- [ ] A guest (not logged in) can read a public collection/item.
- [ ] A guest can download an Open-access essence.
- [ ] A real collector who had attribution-derived access still has read access
      to their collection/items (confirms the backfill).
- [ ] An admin retains full access, including preservation masters.
- [ ] A contact-only user holds no grants and cannot access restricted material.

## Rollback notes

- The migration is additive (`collection_users` table); it does not drop or
  rewrite existing data, so a code rollback can leave the table in place.
- `collector_backfill` is idempotent and only inserts; re-running is safe.
- `contact_grants_cleanup` and the orphan prune are destructive `delete_all`s —
  rely on the pre-flight DB backup if rows must be restored.
- All grant tables are paper-trail tracked except the bulk insert/delete paths
  used here (which deliberately bypass callbacks for performance); the DB backup
  is the source of truth for recovery.
