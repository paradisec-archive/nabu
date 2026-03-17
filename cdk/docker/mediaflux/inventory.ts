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

  if (exitCode !== undefined) {
    const message = `Inventory binary failed (exit code ${exitCode})`;
    const tail = (path: string) => readFileSync(path, 'utf-8').split('\n').slice(-100).join('\n');
    console.error(message);
    Sentry.captureException(new Error(message), {
      extra: { stdout: tail('/tmp/inventory/stdout.log'), stderr: tail('/tmp/inventory/stderr.log') },
    });
    await Sentry.flush(5000);
    process.exit(1);
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
