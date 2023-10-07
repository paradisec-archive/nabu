import fs from 'node:fs';
import { execSync } from 'node:child_process';

import { Cron } from 'croner';
import { SESClient, SendEmailCommand } from '@aws-sdk/client-ses';

const sesClient = new SESClient({ region: 'ap-southeast-2' });

const RAKE_JOBS = [
  { name: 'Mint Dois', when: '10 1 * * *', what: 'archive:mint_dois' }
];

const protectCallback = (job: Cron) => console.log(`Call at ${new Date().toISOString()} were blocked by call started at ${job.currentRun()?.toISOString()}`);

try {
  fs.unlinkSync('/app/log/delayed_job.log')
} catch (err) {
}

RAKE_JOBS.forEach(({ when, name, what }) => Cron(
  when,
  { name, protect: protectCallback },
  async (job: Cron) => {
    let output = '';
    console.log(`Call started at ${job.currentRun()?.toISOString()} started`);

    try {
      output = execSync(`bundle exec rake ${what} 2>&1`).toString();
      console.log(`Call started at ${job.currentRun()?.toISOString()} finished ${new Date().toISOString()}`);
    } catch (e) {
      output = (e as any).stdout.toString();
      console.error(`Call started at ${job.currentRun()?.toISOString()} failed ${new Date().toISOString()}`);
    }
    console.log(output);

    if (output.length < 2) { // NOTE: Ignore any new lines etc
      return;
    }

    const command = new SendEmailCommand({
      Destination: {
        ToAddresses: ['admin@paradisec.org.au', 'johnf@inodes.org', 'jferlito@gmail.com']
      },
      Message: {
        Body: {
          Text: { Data: `The job had the following output:\n\n${output}` }
        },
        Subject: { Data: `Paradisec Scheduled Job - ${name}` }
      },
      Source: 'admin@paradisec.org.au'
    });

    try {
      await sesClient.send(command);
    } catch (error) {
      console.log('SES Error', error);
    }
  },
));

