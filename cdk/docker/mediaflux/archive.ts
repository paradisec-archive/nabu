import { execFileSync } from 'node:child_process';
import { createWriteStream, mkdirSync, rmSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

import { GetObjectCommand, type GetObjectCommandOutput, S3Client } from '@aws-sdk/client-s3';
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: 'production',
});

// unimelb-mf-upload only accepts local paths, so the object has to land on a filesystem first.
// Fargate ephemeral storage stops at 200 GiB and that is the platform maximum, not a setting we can
// raise, so anything near it goes to the EFS scratch volume instead (docs/mediaflux-backup-event-loss.md).
const LARGE_OBJECT_THRESHOLD_BYTES = 180 * 1024 ** 3;

// Set once the scratch directory exists, so the top-level handler can still remove it. EFS scratch
// outlives the task, so a file left behind is billed until someone notices.
let cleanupScratch = () => {};

type UploadSummary = {
  uploadedFiles: number;
  skippedFiles: number;
  failedFiles: number;
  totalFiles: number;
  uploadedBytes: string;
  uploadSpeed: string;
  execTime: string;
};

const parseUploadOutput = (stdout: string): UploadSummary | null => {
  const lines = stdout.split('\n');

  const getValue = (label: string): string | undefined => {
    const line = lines.find((l) => l.includes(label));

    return line?.split(':').slice(1).join(':').trim();
  };

  const uploadedFiles = getValue('Uploaded files');
  if (uploadedFiles === undefined) {
    return null;
  }

  return {
    uploadedFiles: Number.parseInt(uploadedFiles, 10),
    skippedFiles: Number.parseInt(getValue('Skipped files') ?? '0', 10),
    failedFiles: Number.parseInt(getValue('Failed files') ?? '0', 10),
    totalFiles: Number.parseInt(getValue('Total files') ?? '0', 10),
    uploadedBytes: getValue('Uploaded bytes') ?? 'unknown',
    uploadSpeed: getValue('Upload speed') ?? 'unknown',
    execTime: getValue('Exec time') ?? 'unknown',
  };
};

const main = async () => {
  const bucket = process.env.S3_BUCKET;
  const key = process.env.S3_KEY;

  if (!bucket || !key) {
    console.error('Error: S3_BUCKET and S3_KEY environment variables must be set');
    process.exit(1);
  }

  console.log(`Processing s3://${bucket}/${key}`);

  const dir = dirname(key);
  const filename = basename(key);

  // Download from S3
  const s3 = new S3Client();
  let response: GetObjectCommandOutput;
  try {
    response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
  } catch (error) {
    const err = error as Error & { $metadata?: { httpStatusCode?: number } };
    // This task is triggered by an S3 "Object Created" event, but Fargate cold-start means the
    // object can be deleted or replaced before we fetch it. For a backup job a vanished source key
    // is an expected race, not a crash: log it and report at warning level (so a spike stays
    // visible) rather than letting it surface as a generic "Unexpected error" (NABU-NF).
    if (err.name === 'NoSuchKey' || err.$metadata?.httpStatusCode === 404) {
      const message = `Object no longer exists, skipping: s3://${bucket}/${key}`;
      console.warn(message);
      Sentry.captureMessage(message, 'warning');
      await Sentry.flush(5000);
      process.exit(0);
    }
    throw error;
  }

  if (!response.Body) {
    const err = new Error(`Empty response body for s3://${bucket}/${key}`);
    Sentry.captureException(err);
    console.error(err.message);
    await Sentry.flush(5000);
    process.exit(1);
  }

  const size = response.ContentLength ?? 0;
  const scratchBase = size > LARGE_OBJECT_THRESHOLD_BYTES && process.env.LARGE_OBJECT_SCRATCH_DIR ? process.env.LARGE_OBJECT_SCRATCH_DIR : '/tmp';
  // Always work in a job-scoped subdirectory: the EFS volume is shared between concurrent jobs, and
  // it keeps the cleanup below from ever being pointed at /tmp itself.
  const scratchDir = join(scratchBase, process.env.AWS_BATCH_JOB_ID ?? `nabu-${process.pid}`);
  const tmpPath = join(scratchDir, filename);

  mkdirSync(scratchDir, { recursive: true });
  cleanupScratch = () => {
    try {
      rmSync(scratchDir, { recursive: true, force: true });
    } catch (error) {
      console.error(`Failed to clean up ${scratchDir}`, error);
    }
  };

  const writeStream = createWriteStream(tmpPath);
  await pipeline(Readable.fromWeb(response.Body.transformToWebStream()), writeStream);
  console.log(`Downloaded ${size} bytes to ${tmpPath}`);

  // Upload to MediaFlux
  let stdout: string;
  try {
    stdout = execFileSync(
      '/app/mf/bin/unix/unimelb-mf-upload',
      [
        '--nb-queriers',
        '4',
        '--nb-workers',
        '8',
        '--split',
        '--create-parents',
        '--dest',
        `/projects/proj-1190_paradisec_backup-1128.4.248/paradisec/${dir}`,
        tmpPath,
      ],
      // Capture stderr (rather than inheriting it) so the upload binary's actual failure output is
      // attached to the Sentry report — inheriting left err.stderr null and the failures undiagnosable.
      // maxBuffer is raised because a verbose failure can exceed the 1 MiB default and mask the real error.
      { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'pipe'], maxBuffer: 50 * 1024 * 1024 },
    );
  } catch (error) {
    const err = error as Error & { status?: number; stdout?: string; stderr?: string };
    const message = `Upload binary failed for ${key} (exit code ${err.status})`;
    console.error(message);
    console.error(err.stdout ?? '');
    // Keep the binary's stderr in the container logs too, now that it is no longer inherited.
    console.error(err.stderr ?? '');
    Sentry.captureException(new Error(message), {
      extra: { bucket, key, stdout: err.stdout, stderr: err.stderr },
    });
    cleanupScratch();
    await Sentry.flush(5000);
    process.exit(1);
  }

  // Parse and log summary
  const summary = parseUploadOutput(stdout);
  if (summary) {
    console.log('Upload summary:', JSON.stringify(summary));

    if (summary.failedFiles > 0) {
      const message = `${summary.failedFiles} file(s) failed to upload for ${key}`;
      console.error(message);
      Sentry.captureException(new Error(message), {
        extra: { bucket, key, summary },
      });
      cleanupScratch();
      await Sentry.flush(5000);
      process.exit(1);
    }

    if (summary.skippedFiles > 0) {
      console.log(`${summary.skippedFiles} file(s) skipped (already exist)`);
    }
  } else {
    const message = `Unable to parse upload output for ${key}`;
    console.error(message);
    console.error('Raw output:', stdout);
    Sentry.captureException(new Error(message), {
      extra: { bucket, key, stdout },
    });
    cleanupScratch();
    await Sentry.flush(5000);
    process.exit(1);
  }

  cleanupScratch();
  console.log(`Cleaned up ${scratchDir}`);

  await Sentry.flush(5000);
};

main().catch(async (err) => {
  console.error('Unexpected error:', err);
  cleanupScratch();
  Sentry.captureException(err);
  await Sentry.flush(5000);
  process.exit(1);
});
