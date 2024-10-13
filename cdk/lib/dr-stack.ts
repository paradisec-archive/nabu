import * as cdk from 'aws-cdk-lib';
import type { Construct } from 'constructs';

import * as s3 from 'aws-cdk-lib/aws-s3';

import type { Environment } from './types';
import { NagSuppressions } from 'cdk-nag';

export class DrStack extends cdk.Stack {
  public drBucket: s3.IBucket;

  public metaDrBucket: s3.IBucket;

  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      // account,
      region,
      env,
    } = environment;

    if (env !== 'prod') {
      throw new Error('DR stack can only be deployed to prod');
    }
    if (region !== 'ap-southeast-4') {
      console.log(region);
      throw new Error('DR stack can only be deployed to ap-southeast-4');
    }

    // ////////////////////////
    // DR Meta Bucket
    // ////////////////////////
    this.metaDrBucket = new s3.Bucket(this, 'MetaBucket', {
      bucketName: `${appName}-metadr-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    NagSuppressions.addResourceSuppressions(this.metaDrBucket, [
      { id: 'AwsSolutions-S1', reason: "This bucket holds logs for other buckets and we don't want a loop" },
    ]);

    // ////////////////////////
    // Dr bucket
    // ////////////////////////

    this.drBucket = new s3.Bucket(this, 'DrBucket', {
      bucketName: `${appName}-catalogdr-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      lifecycleRules: [{ abortIncompleteMultipartUploadAfter: cdk.Duration.days(7) }],
      versioned: env === 'prod',
      inventories: [
        {
          destination: {
            bucket: this.metaDrBucket,
            prefix: 'inventories/catalogdr',
          },
          frequency: s3.InventoryFrequency.WEEKLY,
          includeObjectVersions: s3.InventoryObjectVersion.ALL,
          optionalFields: [
            'Size',
            'LastModifiedDate',
            'StorageClass',
            'ReplicationStatus',
            'IntelligentTieringAccessTier',
            'ChecksumAlgorithm',
            'ETag',
          ],
        },
      ],
      removalPolicy: cdk.RemovalPolicy.RETAIN,
      serverAccessLogsBucket: this.metaDrBucket,
      serverAccessLogsPrefix: `s3-access-logs/${appName}-catalogdr-${env}`,
    });

    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
