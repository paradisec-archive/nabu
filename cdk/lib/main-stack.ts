import * as cdk from 'aws-cdk-lib';
import type { Construct } from 'constructs';

import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';

import type { Environment } from './types';
import { NagSuppressions } from 'cdk-nag';

export class MainStack extends cdk.Stack {
  public catalogBucket: s3.IBucket;

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
    const metaBucket = new s3.Bucket(this, 'MetaBucket', {
      bucketName: `${appName}-meta-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });
    NagSuppressions.addResourceSuppressions(metaBucket, [
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
      inventories: [
        {
          destination: {
            bucket: metaBucket,
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
      serverAccessLogsBucket: metaBucket,
      serverAccessLogsPrefix: `s3-access-logs/${appName}-catalog-${env}`,
    });

    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
