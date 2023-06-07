#!/usr/bin/env node
import 'source-map-support/register';
import { execSync } from 'child_process';
import * as cdk from 'aws-cdk-lib';
import { CdkStack } from '../lib/cdk-stack';
import type { Environment } from '../lib/cdk-stack';

const globals = {
  appName: 'nabu',
  region: 'ap-southeast-2',
};

const environments: Environment[] = [
  {
    ...globals,
    env: 'stage',
    railsEnv: 'staging',
    branchName: 'main',
    account: '847483222616',
    zoneName: 'nabu-stage.paradisec.org.au',
  },
  {
    ...globals,
    env: 'prod',
    railsEnv: 'production',
    branchName: 'production',
    account: '618916419351',
    zoneName: 'nabu-prod.paradisec.org.au',
  },
];

const branchName = execSync('git rev-parse --abbrev-ref HEAD').toString().trim();
const environment = environments.find((env) => env.branchName === branchName);
if (!environment) {
  console.error(`No environment found for branch ${branchName}`);
  process.exit(1);
}

const app = new cdk.App();
new CdkStack(app, `${environment.appName}-stack-${environment.env}`, environment, {
  env: { account: environment.account, region: environment.region },
});
