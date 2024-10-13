import * as cdk from 'aws-cdk-lib';
import type { Construct } from 'constructs';

import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';

import { NagSuppressions } from 'cdk-nag';

import type { Environment } from './types';

export class MainStack extends cdk.Stack {
  public catalogBucket: s3.IBucket;

  public metaBucket: s3.IBucket;

  public certificate: acm.ICertificate;

  public zone: route53.IHostedZone;

  public tempCertificate: acm.ICertificate;

  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      // account,
      // region,
      // railsEnv,
      drBucket,
      env,
      acmeValue,
      zoneName,
    } = environment;

    // ////////////////////////
    // DNS
    // ////////////////////////

    this.zone = new route53.PublicHostedZone(this, 'HostedZone', {
      zoneName,
      caaAmazon: true,
    });

    // Create lets encrypt txt records for cloudflare
    new route53.TxtRecord(this, 'CloudFlareAcmeTxtRecord', {
      zone: this.zone,
      recordName: `_acme-challenge.${zoneName}`,
      values: [acmeValue],
    });

    // ////////////////////////
    // Certificate
    // ////////////////////////
    const certificate = new acm.Certificate(this, 'Certificate', {
      domainName: `catalog.${zoneName}`,
      validation: acm.CertificateValidation.fromDns(this.zone),
    });

    new ssm.StringParameter(this, 'CertArnParameter', {
      parameterName: '/nabu/resources/certificates/ingest',
      stringValue: certificate.certificateArn,
    });

    // ////////////////////////
    // Temp Cert
    // ////////////////////////
    if (env === 'prod') {
      this.tempCertificate = new acm.Certificate(this, 'TempCertificate', {
        domainName: 'catalog.paradisec.org.au',
        validation: acm.CertificateValidation.fromDns(),
      });
    }

    // ////////////////////////
    // Meta Bucket
    // ////////////////////////
    this.metaBucket = new s3.Bucket(this, 'MetaBucket', {
      bucketName: `${appName}-meta-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    NagSuppressions.addResourceSuppressions(this.metaBucket, [
      { id: 'AwsSolutions-S1', reason: "This bucket holds logs for other buckets and we don't want a loop" },
    ]);

    // ////////////////////////
    // Catalog bucket
    // ////////////////////////

    this.catalogBucket = new s3.Bucket(this, 'CatalogBucket', {
      bucketName: `${appName}-catalog-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      // TODO: Do we want tiering?
      // intelligentTieringConfigurations: [ ],
      // TODO: Decide on lifecycle rules
      lifecycleRules: [{ abortIncompleteMultipartUploadAfter: cdk.Duration.days(7) }],
      versioned: env === 'prod',
      inventories: [
        {
          destination: {
            bucket: this.metaBucket,
            prefix: 'inventories/catalog',
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
      cors: [
        {
          allowedMethods: [s3.HttpMethods.GET],
          allowedOrigins: ['https://catalog.paradisec.org.au', `https:catalog.${zoneName}`],
          allowedHeaders: ['*'],
        },
      ],
      serverAccessLogsBucket: this.metaBucket,
      serverAccessLogsPrefix: `s3-access-logs/${appName}-catalog-${env}`,
      eventBridgeEnabled: true,
    });
    NagSuppressions.addStackSuppressions(this, [
      { id: 'AwsSolutions-IAM4', reason: 'OK with * resources' },
      { id: 'AwsSolutions-IAM5', reason: 'OK with * resources' },
    ]);

    if (env === 'prod') {
      if (!drBucket) {
        throw new Error('DR bucket is required in prod environment');
      }

      const replicationRole = new iam.Role(this, 'CatalogBucketReplicationRole', {
        roleName: 'catalog-bucket-replication-role',
        assumedBy: new iam.ServicePrincipal('s3.amazonaws.com'),
      });

      replicationRole.addToPolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['s3:GetReplicationConfiguration', 's3:ListBucket'],
          resources: [this.catalogBucket.bucketArn],
        }),
      );

      replicationRole.addToPolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: [
            's3:GetObjectVersionForReplication',
            's3:GetObjectVersionAcl',
            's3:GetObjectVersionTagging',
            's3:GetObjectVersion',
            's3:GetObjectLegalHold',
            's3:GetObjectRetention',
          ],
          resources: [this.catalogBucket.arnForObjects('*')],
        }),
      );

      NagSuppressions.addResourceSuppressions(
        replicationRole,
        [
          {
            id: 'AwsSolutions-IAM5',
            reason: 'All wildcard permission are on purpose for replication',
          },
        ],
        true,
      );

      replicationRole.addToPolicy(
        new iam.PolicyStatement({
          effect: iam.Effect.ALLOW,
          actions: ['s3:ReplicateObject', 's3:ReplicateDelete', 's3:ReplicateTags', 's3:GetObjectVersionTagging'],
          resources: [`${drBucket.bucketArn}/*`],
        }),
      );

      const cfnBucket = this.catalogBucket.node.defaultChild as s3.CfnBucket;
      cfnBucket.replicationConfiguration = {
        role: replicationRole.roleArn,
        rules: [
          {
            id: drBucket.bucketArn,
            status: 'Enabled',
            priority: 1,
            filter: {},
            destination: {
              bucket: drBucket.bucketArn,
              storageClass: s3.StorageClass.GLACIER_INSTANT_RETRIEVAL.toString(),
            },

            deleteMarkerReplication: {
              status: 'Enabled',
            },
          },
        ],
      };
    }

    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
