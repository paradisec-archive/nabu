#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { AwsSolutionsChecks, NagSuppressions } from 'cdk-nag';

import { MainStack } from '../lib/main-stack';
import { AppStack } from '../lib/app-stack';
import type { AppProps, Environment } from '../lib/types';

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
  const mainStack = new MainStack(app, `${environment.appName}-stack-${environment.env}`, environment, {
    env: { account: environment.account, region: environment.region },
  });

  const props: AppProps = {
    ...environment,
    catalogBucket: mainStack.catalogBucket,
    zone: mainStack.zone,
    tempCertificate: mainStack.tempCertificate,
  };

  const stack = new AppStack(app, `${environment.appName}-appstack-${environment.env}`, props, {
    env: { account: environment.account, region: environment.region },
  });
  NagSuppressions.addStackSuppressions(stack, [
    { id: 'AwsSolutions-IAM5', reason: 'Too many false positives' },
    { id: 'AwsSolutions-EC26', reason: 'Too many false positives' },
  ]);
});

cdk.Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
