import { execFileSync } from 'node:child_process';
import { createReadStream, mkdirSync, openSync, readFileSync } from 'node:fs';

import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: 'production',
});

const main = async () => {
  const bucket = process.env.META_BUCKET;

  if (!bucket) {
    console.error('Error: META_BUCKET environment variable must be set');
    process.exit(1);
  }

  mkdirSync('/tmp/inventory');
  mkdirSync('/tmp/inventory/empty');

  console.log('Running mediaflux inventory check...');

  const stdoutFd = openSync('/tmp/inventory/stdout.log', 'w');
  const stderrFd = openSync('/tmp/inventory/stderr.log', 'w');

  let exitCode: number | undefined;
  try {
    execFileSync(
      '/app/mf/bin/unix/unimelb-mf-check',
      [
        '--direction',
        'down',
        '--quiet',
        '--output',
        '/tmp/inventory/files.csv',
        '--detailed-output',
        '/tmp/inventory/empty',
        '/projects/proj-1190_paradisec_backup-1128.4.248/paradisec',
      ],
      { stdio: ['pipe', stdoutFd, stderrFd], timeout: 60 * 60 * 1000 },
    );
  } catch (error) {
    exitCode = (error as Error & { status?: number }).status;
  }

  // Dump full output to CloudWatch
  console.log('--- stdout ---');
  execFileSync('cat', ['/tmp/inventory/stdout.log'], { stdio: ['pipe', 'inherit', 'inherit'] });
  console.log('--- stderr ---');
  execFileSync('cat', ['/tmp/inventory/stderr.log'], { stdio: ['pipe', 'inherit', 'inherit'] });

  const tail = (path: string) => readFileSync(path, 'utf-8').split('\n').slice(-100).join('\n');

  const fail = async (message: string) => {
    console.error(message);
    Sentry.captureException(new Error(message), {
      extra: { stdout: tail('/tmp/inventory/stdout.log'), stderr: tail('/tmp/inventory/stderr.log') },
    });
    await Sentry.flush(5000);
    process.exit(1);
  };

  if (exitCode !== undefined) {
    await fail(`Inventory binary failed (exit code ${exitCode})`);
  }

  // The check summary reports e.g. "799,525 assets [checked]" / "801,045 assets [total]".
  // A shortfall means assets were silently skipped (e.g. InvalidPathException aborting a
  // batch), so the CSV is incomplete and must not become the day's inventory.
  const stdout = readFileSync('/tmp/inventory/stdout.log', 'utf-8');
  const summaryCount = (label: string) => {
    const match = stdout.match(new RegExp(`([\\d,]+) assets \\[${label}\\]`));
    return match ? Number(match[1].replace(/,/g, '')) : undefined;
  };

  const checked = summaryCount('checked');
  const total = summaryCount('total');

  if (checked === undefined || total === undefined) {
    await fail('Inventory summary is missing checked/total asset counts; refusing to upload');
  } else if (checked !== total) {
    await fail(`Inventory incomplete: checked ${checked} of ${total} assets; refusing to upload`);
  }

  const today = new Date().toISOString().slice(0, 10);
  const key = `mediaflux-inventory/${today}.csv`;

  const s3 = new S3Client();
  await s3.send(new PutObjectCommand({ Bucket: bucket, Key: key, Body: createReadStream('/tmp/inventory/files.csv') }));

  console.log(`Uploaded inventory to s3://${bucket}/${key}`);

  await Sentry.flush(5000);
};

main().catch(async (err) => {
  console.error('Unexpected error:', err);
  Sentry.captureException(err);
  await Sentry.flush(5000);
  process.exit(1);
});
