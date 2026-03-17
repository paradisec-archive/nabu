import { execFileSync } from 'node:child_process';
import { createWriteStream, unlinkSync } from 'node:fs';
import { basename, dirname } from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';

import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: 'production',
});

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
  const tmpPath = `/tmp/${filename}`;

  // Download from S3
  const s3 = new S3Client();
  const response = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));

  if (!response.Body) {
    const err = new Error(`Empty response body for s3://${bucket}/${key}`);
    Sentry.captureException(err);
    console.error(err.message);
    await Sentry.flush(5000);
    process.exit(1);
  }

  const writeStream = createWriteStream(tmpPath);
  await pipeline(Readable.fromWeb(response.Body.transformToWebStream()), writeStream);
  console.log(`Downloaded to ${tmpPath}`);

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
      { encoding: 'utf-8', stdio: ['pipe', 'pipe', 'inherit'] },
    );
  } catch (error) {
    const err = error as Error & { status?: number; stdout?: string; stderr?: string };
    const message = `Upload binary failed for ${key} (exit code ${err.status})`;
    console.error(message);
    console.error(err.stdout ?? '');
    Sentry.captureException(new Error(message), {
      extra: { bucket, key, stdout: err.stdout, stderr: err.stderr },
    });
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
    await Sentry.flush(5000);
    process.exit(1);
  }

  // Cleanup on success
  unlinkSync(tmpPath);
  console.log(`Cleaned up ${tmpPath}`);

  await Sentry.flush(5000);
};

main().catch(async (err) => {
  console.error('Unexpected error:', err);
  Sentry.captureException(err);
  await Sentry.flush(5000);
  process.exit(1);
});
