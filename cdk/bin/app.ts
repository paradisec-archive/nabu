#!/usr/bin/env node
import * as cdk from 'aws-cdk-lib';
import 'source-map-support/register';
import { AwsSolutionsChecks, NagSuppressions } from 'cdk-nag';
import { AppStack } from '../lib/app-stack';
import { DrStack } from '../lib/dr-stack';
import { MainStack } from '../lib/main-stack';
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
    acmeValue: 'PM0DillUQGnKlpqsD9dmT-s8U6Jq7WeSPEKOrptZWQI',
    adminAcmePath: '.well-known/acme-challenge/kC-4NOypAEfhGNjvqrh-hQpMAQHVYKseb8YIPAe-_aPbA9pCVA3KHokJ0Do-6qoa',
    adminAcmeValue: 'kC-4NOypAEfhGNjvqrh-hQpMAQHVYKseb8YIPAe-_aPbA9pCVA3KHokJ0Do-6qoa.r54qAqCZSs4xyyeamMffaxyR1FWYVb5OvwUh8EcrhpI',
    cloudflare: 'catalog.nabu-stage.paradisec.org.au.cdn.cloudflare.net',
  },
  {
    ...globals,
    env: 'prod',
    railsEnv: 'production',
    branchNames: ['production'],
    account: '618916419351',
    zoneName: 'nabu-prod.paradisec.org.au',
    acmeValue: 'coAr3vAsNUwrReLqZAtAPgfcwvnqPCPovbyYTp791i8',
    adminAcmePath: '/.well-known/acme-challenge/FIXME',
    adminAcmeValue: 'FIXME',
    cloudflare: 'catalog.nabu-prod.paradisec.org.au.cdn.cloudflare.net',
  },
];
const prod = environments.find((env) => env.env === 'prod');
if (!prod) {
  console.error('No prod environment found');
  process.exit(1);
}

const app = new cdk.App();

const prodEnvironment = environments.find((env) => env.env === 'prod');
if (!prodEnvironment) {
  throw new Error('No prod environment found');
}
const drStack = new DrStack(
  app,
  `${prodEnvironment.appName}-drstack-${prodEnvironment.env}`,
  { ...prodEnvironment, region: 'ap-southeast-4' },
  {
    env: { account: prodEnvironment.account, region: 'ap-southeast-4' },
  },
);

environments.forEach((environment) => {
  const mainStack = new MainStack(
    app,
    `${environment.appName}-stack-${environment.env}`,
    { drBucket: environment.env === 'prod' ? drStack.drBucket : undefined, ...environment },
    {
      env: { account: environment.account, region: environment.region },
    },
  );

  const props: AppProps = {
    ...environment,
    catalogBucket: mainStack.catalogBucket,
    metaBucket: mainStack.metaBucket,
    drBucket: drStack.drBucket,
    metaDrBucket: drStack.metaDrBucket,
    zone: mainStack.zone,
    adminCertificate: mainStack.adminCertificate,
    catalogCertificate: mainStack.catalogCertificate,
    tempCertificate: mainStack.tempCertificate,
  };

  const stack = new AppStack(app, `${environment.appName}-appstack-${environment.env}`, props, {
    env: { account: environment.account, region: environment.region },
  });
  NagSuppressions.addStackSuppressions(stack, [
    { id: 'AwsSolutions-IAM4', reason: 'Managed Policies are fine for us, we can live with the resource wildcard' },
    { id: 'AwsSolutions-IAM5', reason: 'Too many false positives' },
    { id: 'AwsSolutions-EC26', reason: 'Too many false positives' },
    { id: 'AwsSolutions-L1', reason: 'This is almost always a CDK created thing with an older runtime' },
  ]);
});

cdk.Aspects.of(app).add(new AwsSolutionsChecks({ verbose: true }));
