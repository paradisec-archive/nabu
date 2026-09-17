# Why Mediaflux backup uploads go missing

Investigation of the gap between `nabu-catalog-prod` object-created events and
Mediaflux upload containers, 2026-09-17. Window analysed: 2026-06-22 → 2026-09-18.

## Summary

The backup path silently drops a large fraction of objects. Nothing reports it:
EventBridge records success, no container runs, so no code executes to tell
Sentry. The weekly size comparison is the only thing that notices, a week later.

There are three distinct loss modes, all of which look like success to
EventBridge. The dominant one on an ordinary day is subnet IP exhaustion.

| Signal | Value |
|---|---|
| EventBridge `Invocations` | 115,304 |
| EventBridge `FailedInvocations` | 0 |
| Containers that logged `Processing s3://` | 74,780 |

The previously reported container count of 71,723 came from Logs Insights
`count_distinct`, which is approximate. An exact `count(*)` gives 74,780. The gap
is real regardless — it is just distributed very differently than a flat 38%.

## The gap is not uniform

84% of all invocations in the window landed on a single day.

| Date (UTC) | Invocations | Containers |
|---|---|---|
| 2026-07-14 | 96,529 | 3,087 |
| all other days | 18,775 | 71,693 |

On 2026-07-14, 96,191 events arrived in two hours (11:00Z and 12:00Z), roughly
16/s. About 96.8% of that day's events never produced a container.

On other days containers *exceed* invocations, because
`mflux/batch-mediaflux-upload.sh` launches tasks directly rather than through the
rule. Comparing the two totals without separating those out understates the
event-driven loss.

## Loss mode 1 — `RunTask` throttling

CloudTrail, 1,250 sampled `RunTask` calls during the 2026-07-14 12:00Z hour:

| Outcome | Share |
|---|---|
| task launched | 57.0% |
| `ThrottlingException` | 38.2% |
| `failures[]` vCPU limit | 4.9% |

EventBridge retries throttled target calls, but the rule has no DLQ, so anything
that exhausts retries is gone with no record.

## Loss mode 2 — vCPU limit reported as success

```
"responseElements": {
  "tasks": [],
  "failures": [{"reason": "You've reached the limit on the number of vCPUs you can run concurrently"}]
}
```

`RunTask` returned HTTP 200 with an empty `tasks` array. EventBridge counts that
as a successful invocation, which is why `FailedInvocations` is 0. **A DLQ on the
target does not catch this** — the API call succeeded.

The Fargate On-Demand vCPU quota is 4,000. The task requests 16 vCPU, so the
ceiling is 250 concurrent tasks.

## Loss mode 3 — tasks that cannot get a network interface

This is the one that bites every day.

On 2026-09-16 every sampled `RunTask` call succeeded (1,317 from the rule, 241
manual), yet only 744 containers logged. Inspecting the cluster's stopped tasks:

| Count | Stop code | Reason |
|---|---|---|
| 366 | `EssentialContainerExited` | normal completion |
| 151 | `TaskFailedToStart` | `InsufficientFreeAddressesInSubnet` |

29% of tasks were accepted by `RunTask`, entered `PROVISIONING`, failed to create
an ENI, and stopped without running the container or writing a log line.

### Why the subnets are full

`appSubnets` (`cdk/lib/app-stack.ts`) reads
`/usyd/resources/subnets/public/apse2{a,b,c}-id`. Those are the **Ingress**
subnets, shared with `Ingress-alb-01`, `Ingress-nlb-01` and a VPC endpoint:

| Subnet | CIDR | Free IPs |
|---|---|---|
| `subnet-05d93362e947058bc` | 10.122.113.48/28 | 0 |
| `subnet-0ed390a90922cd9af` | 10.122.113.64/28 | 0 |
| `subnet-05125623fb0c0050a` | 10.122.113.80/28 | 0 |

Each `/28` has 11 usable addresses, 33 in total, and all three are currently
full. The Application subnets (`/usyd/resources/subnets/private/*`) are also
`/28`s, so moving helps but does not remove the ceiling. This VPC cannot support
more than roughly 10–20 concurrent Fargate tasks under any subnet choice, which
means concurrency has to be bounded rather than left to fan-out.

## Objects that can never be backed up

The task downloads the whole object to `/tmp` before invoking the CLI. Fargate
ephemeral storage is capped at 200 GiB, which the task already requests. These
exceed it and fail with `ENOSPC` on every attempt:

| Key | Size |
|---|---|
| `BJM02/098/BJM02-098-01.mkv` | 276 GiB |
| `SMR1/elicitation30/SMR1-elicitation30-fad.mkv` | 247 GiB |
| `SMR1/elicitation29/SMR1-elicitation29-fad.mkv` | 243 GiB |
| `SMR1/elicitation27/SMR1-elicitation27-fad.mkv` | 215 GiB |
| `SMR1/kin01/SMR1-kin01-m.mkv` | 210 GiB |

`unimelb-mf-upload --help` confirms it only accepts local directory or file
paths — there is no stdin or stream mode, so the object has to land on a
filesystem first. `--split` chunks files over 1 GB for parallel transfer but
still reads from a local path. Streaming S3 straight to the CLI is therefore not
available; the fix has to give the task a filesystem larger than 200 GiB.

## What this does not explain

Nothing here accounts for the failures that *are* reaching Sentry
(`Unable to parse upload output`, `Upload binary failed`,
`N file(s) failed to upload`). Those are separate, still occurring, and still
have nothing that retries them.
