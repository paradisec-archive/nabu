#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { CdkStack } from '../lib/cdk-stack';
import { NlbStack } from '../lib/nlb-stack';
import { CommonStack } from '../lib/common-stack';
import type { Environment } from '../lib/types';

const globals = {
  appName: 'nabu',
  region: 'ap-southeast-2',
};

const environments: Environment[] = [
  {
    ...globals,
    env: 'stage',
    railsEnv: 'staging',
    branchNames: ['main', 'aws'],
    account: '847483222616',
    zoneName: 'nabu-stage.paradisec.org.au',
  },
  {
    ...globals,
    env: 'prod',
    railsEnv: 'production',
    branchNames: ['production'],
    account: '618916419351',
    zoneName: 'nabu-prod.paradisec.org.au',
  },
];
const prod = environments.find((env) => env.env === 'prod');
if (!prod) {
  console.error('No prod environment found');
  process.exit(1);
}

const app = new cdk.App();

environments.forEach((environment) => {
  new NlbStack(app, `${environment.appName}-nlbstack-${environment.env}`, environment, {
    env: { account: environment.account, region: environment.region },
  });

  new CdkStack(app, `${environment.appName}-stack-${environment.env}`, environment, {
    env: { account: environment.account, region: environment.region },
  });
});

new CommonStack(app, `${prod.appName}-stack-common`, {
  env: { account: prod.account, region: prod.region },
});
