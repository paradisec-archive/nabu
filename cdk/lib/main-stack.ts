import * as cdk from 'aws-cdk-lib';
import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { NagSuppressions } from 'cdk-nag';
import type { Construct } from 'constructs';

import type { Environment } from './types';

export class MainStack extends cdk.Stack {
  public catalogBucket: s3.IBucket;

  public metaBucket: s3.IBucket;

  public catalogCertificate: acm.ICertificate;
  public adminCertificate: acm.ICertificate;
  public tempCertificate: acm.ICertificate;

  public zone: route53.IHostedZone;

  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const { appName, drBucket, env, acmeValue, zoneName } = environment;

    // ////////////////////////
    // DNS
    // ////////////////////////

    this.zone = new route53.PublicHostedZone(this, 'HostedZone', {
      zoneName,
    });

    // Create lets encrypt txt records for cloudflare
    new route53.TxtRecord(this, 'CloudFlareAcmeTxtRecord', {
      zone: this.zone,
      recordName: `_acme-challenge.${zoneName}`,
      values: [acmeValue],
    });

    new route53.CaaRecord(this, 'CloudflareAndAmazonCaa', {
      zone: this.zone,
      values: [
        { flag: 0, tag: route53.CaaTag.ISSUE, value: 'amazon.com' },
        { flag: 0, tag: route53.CaaTag.ISSUE, value: 'pki.goog; cansignhttpexchanges=yes' },
        { flag: 0, tag: route53.CaaTag.ISSUEWILD, value: 'pki.goog; cansignhttpexchanges=yes' },
        { flag: 0, tag: route53.CaaTag.ISSUE, value: 'letsencrypt.org' },
        { flag: 0, tag: route53.CaaTag.ISSUEWILD, value: 'letsencrypt.org' },
        { flag: 0, tag: route53.CaaTag.ISSUE, value: 'ssl.com' },
        { flag: 0, tag: route53.CaaTag.ISSUEWILD, value: 'ssl.com' },
      ],
    });

    // ////////////////////////
    // Certificate
    // ////////////////////////
    const catalogCertificate = new acm.Certificate(this, 'Certificate', {
      domainName: `catalog.${zoneName}`,
      validation: acm.CertificateValidation.fromDns(this.zone),
    });
    this.catalogCertificate = catalogCertificate;

    const adminCertificate = new acm.Certificate(this, 'AdminCertificate', {
      domainName: `admin.catalog.${zoneName}`,
      validation: acm.CertificateValidation.fromDns(this.zone),
    });
    this.adminCertificate = adminCertificate;

    if (env === 'prod') {
      this.tempCertificate = new acm.Certificate(this, 'TempCertificate', {
        domainName: 'catalog.paradisec.org.au',
        validation: acm.CertificateValidation.fromDns(),
      });
    }

    // ////////////////////////
    // Service endpoint for Nabu NLB
    // ////////////////////////
    const nlb = elbv2.NetworkLoadBalancer.fromLookup(this, 'NLB', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/network-load-balance/application/arn'),
    });

    const endpoint = new ec2.VpcEndpointService(this, 'NlbEndpointService', {
      vpcEndpointServiceLoadBalancers: [nlb],
      acceptanceRequired: false,
    });

    new ssm.StringParameter(this, 'NLBEndpointServiceParameter', {
      parameterName: '/nabu/resources/nlb-endpoint/service-name',
      stringValue: endpoint.vpcEndpointServiceName,
    });

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

    // Allow ALBs to log
    const albLogBucketPolicy = new iam.PolicyStatement({
      effect: iam.Effect.ALLOW,
      principals: [new iam.ArnPrincipal('arn:aws:iam::783225319266:root')],
      actions: ['s3:PutObject'],
      resources: [`${this.metaBucket.bucketArn}/s3-access-logs/*`],
      conditions: {
        StringEquals: {
          's3:x-amz-acl': 'bucket-owner-full-control',
        },
      },
    });
    this.metaBucket.addToResourcePolicy(albLogBucketPolicy);

    // ////////////////////////
    // Catalog bucket
    // ////////////////////////
    let replicationRules: s3.ReplicationRule[] | undefined;
    if (env === 'prod') {
      if (!drBucket) {
        throw new Error('DR bucket is required in prod environment');
      }

      replicationRules = [
        {
          id: 'dr-replica-mel',
          priority: 1,
          destination: drBucket,
          storageClass: s3.StorageClass.DEEP_ARCHIVE,
          deleteMarkerReplication: true,
        },
      ];
    }

    this.catalogBucket = new s3.Bucket(this, 'CatalogBucket', {
      bucketName: `${appName}-catalog-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
      enforceSSL: true,
      lifecycleRules: [
        { abortIncompleteMultipartUploadAfter: cdk.Duration.days(7) },
        {
          transitions: [{ storageClass: s3.StorageClass.GLACIER_INSTANT_RETRIEVAL, transitionAfter: cdk.Duration.days(90) }],
          tagFilters: { archive: 'true' },
        },
      ],
      replicationRules: replicationRules,
      versioned: env === 'prod',
      inventories: [
        {
          destination: {
            bucket: this.metaBucket,
            prefix: 'inventories/catalog',
          },
          frequency: s3.InventoryFrequency.WEEKLY,
          includeObjectVersions: s3.InventoryObjectVersion.ALL,
          optionalFields: ['Size', 'LastModifiedDate', 'StorageClass', 'ReplicationStatus', 'IntelligentTieringAccessTier', 'ChecksumAlgorithm', 'ETag'],
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

    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
