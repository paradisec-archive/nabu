# Scheduled work runs as Solid Queue recurring tasks in the jobs service

Scheduled maintenance (DOI minting, the S3, replication and Mediaflux catalogue validators, and unconfirmed-user deletion)
used to run in a separate production-only ECS service driven by rufus-scheduler. That service was a second job runtime with
its own task definition, IAM role, error-reporting hook and ad hoc SES emailing, and its runs were invisible in Mission Control.

We decided that each of these tasks is an ordinary Active Job on the `maintenance` queue, declared under the `production`
key of `config/recurring.yml` and run by the existing `jobs` service. There is one job runtime to deploy, monitor and
secure; runs appear in Mission Control, failures reach Sentry through the standard Active Job integration, and the schedule
is versioned with the code it runs.

## Considered options

- **Keep rufus-scheduler in its own service.** Rejected: duplicates the job runtime and every scheduled task stays a
  bespoke block of Ruby rather than a job.
- **EventBridge scheduled ECS tasks per job.** Rejected: moves the schedule into CDK, away from the code, and each run
  boots a full Rails container with no Mission Control record.
- **System cron or `whenever` in the app container.** Rejected: ECS runs one process per container, so this still needs a
  dedicated service, and errors do not flow through Active Job.

## Consequences

- Scheduled tasks run only where `recurring.yml` declares them, so staging never mints DOIs or deletes users.
- The `maintenance` queue has a single-threaded worker so a long validator cannot starve user-facing jobs, and the jobs
  declare no retries because the next scheduled run is the retry.
- Solid Queue reads `recurring.yml` at supervisor boot, so schedule changes take effect on the next deploy of the jobs
  service.
- Every recurring entry must land on a queue a worker serves; `spec/config/queue_spec.rb` checks this.
