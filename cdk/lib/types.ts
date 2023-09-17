import type { IHostedZone } from 'aws-cdk-lib/aws-route53';
import type { IBucket } from 'aws-cdk-lib/aws-s3';

export type Environment = {
  readonly appName: string,
  readonly region: string,
  readonly env: string,
  readonly railsEnv: string,
  readonly branchNames: string[],
  readonly account: string,
  readonly zoneName: string,
};

export type AppProps = Environment & {
  readonly catalogBucket: IBucket,
  readonly zone: IHostedZone,
};
