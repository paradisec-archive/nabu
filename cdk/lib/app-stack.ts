import { execSync } from 'node:child_process';

import * as cdk from 'aws-cdk-lib';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as batch from 'aws-cdk-lib/aws-batch';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import * as cloudwatchActions from 'aws-cdk-lib/aws-cloudwatch-actions';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecrAssets from 'aws-cdk-lib/aws-ecr-assets';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as efs from 'aws-cdk-lib/aws-efs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as opensearch from 'aws-cdk-lib/aws-opensearchservice';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as sns from 'aws-cdk-lib/aws-sns';
import * as sqs from 'aws-cdk-lib/aws-sqs';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import type { Construct } from 'constructs';

import { acknowledgeNag } from './nag';
import type { AppProps } from './types';

const SENTRY_DSN = 'https://aa8f28b06df84f358949b927e85a924e@o4504801902985216.ingest.sentry.io/4504801910980608';

// The ceiling here is the VPC, not the Fargate vCPU quota: the application subnets are /28s, so
// there are only a few dozen task addresses in the whole account.
const MEDIAFLUX_JOB_VCPUS = 4;
const MEDIAFLUX_MAX_CONCURRENT_JOBS = 10;
const MEDIAFLUX_SCRATCH_PATH = '/mnt/mediaflux-scratch';

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, appProps: AppProps, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      region,
      railsEnv,
      env,
      zoneName,

      catalogBucket,
      metaBucket,
      metaDrBucket,
      drBackupVault,
      downloaderBucket,
      zone,
      catalogCertificate,
      adminCertificate,
      tempCertificate,
      cloudflare,
      adminAcmePath,
      adminAcmeValue,
    } = appProps;

    // ////////////////////////
    // Network
    // ////////////////////////

    const vpc = ec2.Vpc.fromLookup(this, 'VPC', {
      vpcId: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/vpc-id'),
    });

    const dataSubnets = ['a', 'b', 'c'].map((az, index) => {
      const subnetId = ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/isolated/apse2${az}-id`);
      const availabilityZone = `ap-southeast-2${az}`;
      const subnet = ec2.Subnet.fromSubnetAttributes(this, `DataSubnet${index}`, { subnetId, availabilityZone });
      cdk.Annotations.of(subnet).acknowledgeWarning('@aws-cdk/aws-ec2:noSubnetRouteTableId');

      return subnet;
    });

    const appSubnets = ['a', 'b', 'c'].map((az, index) => {
      const subnetId = ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/public/apse2${az}-id`);
      const availabilityZone = `ap-southeast-2${az}`;
      const subnet = ec2.Subnet.fromSubnetAttributes(this, `AppSubnet${index}`, { subnetId, availabilityZone });
      cdk.Annotations.of(subnet).acknowledgeWarning('@aws-cdk/aws-ec2:noSubnetRouteTableId');

      return subnet;
    });

    // ////////////////////////
    // Database
    // ////////////////////////

    const db = new rds.DatabaseInstance(this, 'RdsInstance', {
      engine: rds.DatabaseInstanceEngine.mysql({
        version: rds.MysqlEngineVersion.VER_8_0,
      }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MEDIUM),
      // storageEncrypted: true, // NOTE: It defaults to true, but SonarQube doesn't seem to know that
      credentials: rds.Credentials.fromGeneratedSecret('nabu'),
      databaseName: 'nabu',
      vpc,
      vpcSubnets: {
        subnets: dataSubnets,
      },
      enablePerformanceInsights: true,
      deletionProtection: true,
    });
    acknowledgeNag(
      db,
      { id: 'AwsSolutions-RDS3', reason: 'Single AZ app, HA not needed' },
      { id: 'AwsSolutions-RDS11', reason: 'Standard port is fine' },
      { id: 'AwsSolutions-SMG4', reason: "Rails doesn't support rotation" },
      { id: 'AwsSolutions-RDS2', reason: 'FIXME: We should have encryption' }, // FIXME: We should really fix this
    );

    // ////////////////////////
    // Search
    // ////////////////////////
    const searchDomain = new opensearch.Domain(this, 'SearchDomain', {
      capacity: {
        dataNodeInstanceType: 'c7g.xlarge.search', // t3's have some limitations
        dataNodes: 3,
        multiAzWithStandbyEnabled: false, // We don't need that much HA
      },
      ebs: {
        volumeSize: 20,
        volumeType: ec2.EbsDeviceVolumeType.GP3,
        throughput: 125, // These are the minimums
        iops: 3000, // These are the minimums
      },
      version: opensearch.EngineVersion.OPENSEARCH_2_19,
      tlsSecurityPolicy: opensearch.TLSSecurityPolicy.TLS_1_2_PFS,
      enableVersionUpgrade: true,
      enableAutoSoftwareUpdate: true,
      enforceHttps: true,
      nodeToNodeEncryption: true,
      encryptionAtRest: {
        enabled: true,
      },
      vpc,
      vpcSubnets: [
        {
          subnets: dataSubnets,
        },
      ],
      zoneAwareness: {
        enabled: true,
        availabilityZoneCount: 3,
      },
      logging: {
        slowSearchLogEnabled: true,
        appLogEnabled: true,
        slowIndexLogEnabled: true,
      },
    });
    acknowledgeNag(
      searchDomain,
      {
        id: 'AwsSolutions-OS3',
        reason: 'We are indise a VPC, not on the Internet',
      },
      {
        id: 'AwsSolutions-OS4',
        reason: "We don't want to pay for dedicated data nodes",
      },
      {
        id: 'AwsSolutions-OS5',
        reason: 'Should not trigger as anonymous disabled',
      },
    );

    // ////////////////////////
    // ECS Cluster
    // ////////////////////////

    const cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: appName,
      vpc,
      containerInsightsV2: ecs.ContainerInsights.ENHANCED,
    });
    cluster.addDefaultCloudMapNamespace({
      name: 'nabu',
      useForServiceConnect: true,
    });
    acknowledgeNag(cluster, {
      id: 'AwsSolutions-ECS4',
      reason: 'https://github.com/cdklabs/cdk-nag/pull/1927',
    });

    const autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'EcsASG', {
      vpc,
      vpcSubnets: {
        subnets: appSubnets,
      },

      instanceType: new ec2.InstanceType('m6a.xlarge'),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2023(),

      minCapacity: 1,
      maxCapacity: 2, // So we can update EC2 without downtime
      requireImdsv2: true,

      updatePolicy: autoscaling.UpdatePolicy.rollingUpdate({
        minInstancesInService: 1,
      }),

      // keyName: 'nabu',
    });
    acknowledgeNag(
      autoScalingGroup,
      {
        id: 'AwsSolutions-EC26',
        reason: 'EBS coume already encrypted due to AMI defaults',
      },
      {
        id: 'AwsSolutions-AS3',
        reason: 'We can live without the other notifications',
      },
    );
    // needed by service connect
    autoScalingGroup.addToRolePolicy(
      new iam.PolicyStatement({
        actions: ['ecs:Poll'],
        resources: ['*'],
      }),
    );

    const capacityProvider = new ecs.AsgCapacityProvider(this, 'EcsAsgCapacityProvider', {
      autoScalingGroup,
    });
    cluster.addAsgCapacityProvider(capacityProvider);

    // ////////////////////////
    // Application Load Balancer
    // ////////////////////////

    const sslListener = elbv2.ApplicationListener.fromLookup(this, 'AlbSslListener', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
      listenerProtocol: elbv2.ApplicationProtocol.HTTPS,
    });
    sslListener.addCertificates('CatalogCert', [elbv2.ListenerCertificate.fromArn(catalogCertificate.certificateArn)]);
    sslListener.addCertificates('AdminCert', [elbv2.ListenerCertificate.fromArn(adminCertificate.certificateArn)]);
    if (env === 'prod') {
      sslListener.addCertificates('TempCatalogCert', [elbv2.ListenerCertificate.fromArn(tempCertificate.certificateArn)]);
    }

    // ////////////////////////
    // Downloader
    // ////////////////////////

    const downloaderSecrets = new secretsmanager.Secret(this, 'DownloaderSecrets', {
      secretObjectValue: {
        OIDC_CLIENT_ID: cdk.SecretValue.unsafePlainText('secret'),
        OIDC_CLIENT_SECRET: cdk.SecretValue.unsafePlainText('secret'),
        OIDC_REDIRECT_URI: cdk.SecretValue.unsafePlainText('secret'),
        OIDC_ISSUER: cdk.SecretValue.unsafePlainText('secret'),
        SESSION_SECRET: cdk.SecretValue.unsafePlainText('secret'),
      },
    });
    acknowledgeNag(downloaderSecrets, { id: 'AwsSolutions-SMG4', reason: 'No auto rotation needed' });

    const downloaderTaskDefinition = new ecs.Ec2TaskDefinition(this, 'DownloaderTaskDefinition');
    acknowledgeNag(downloaderTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });
    downloaderTaskDefinition.addContainer('DownloaderContainer', {
      containerName: 'downloader',
      memoryLimitMiB: 2048,
      image: ecs.ContainerImage.fromRegistry('ghcr.io/crate-works/downloader'),
      portMappings: [{ name: 'downloader', containerPort: 7000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'DownloaderService' }),
      environment: {
        AWS_REGION: region,
        S3_BUCKET: downloaderBucket.bucketName,
        ROCRATE_API_BASE_URL:
          env === 'prod' ? 'https://admin-catalog.paradisec.org.au/api/v1/oni' : 'https://admin-catalog.nabu-stage.paradisec.org.au/api/v1/oni',
        EMAIL_FROM: 'admin@paradisec.org.au',
        BASE_PATH: '/downloader',
      },
      secrets: {
        SESSION_SECRET: ecs.Secret.fromSecretsManager(downloaderSecrets, 'SESSION_SECRET'),
        OIDC_CLIENT_ID: ecs.Secret.fromSecretsManager(downloaderSecrets, 'OIDC_CLIENT_ID'),
        OIDC_CLIENT_SECRET: ecs.Secret.fromSecretsManager(downloaderSecrets, 'OIDC_CLIENT_SECRET'),
        OIDC_REDIRECT_URI: ecs.Secret.fromSecretsManager(downloaderSecrets, 'OIDC_REDIRECT_URI'),
        OIDC_ISSUER: ecs.Secret.fromSecretsManager(downloaderSecrets, 'OIDC_ISSUER'),
      },
    });
    downloaderBucket.grantReadWrite(downloaderTaskDefinition.taskRole);
    downloaderTaskDefinition.addToTaskRolePolicy(
      new iam.PolicyStatement({
        actions: ['ses:SendRawEmail', 'ses:SendEmail'],
        resources: ['*'],
      }),
    );

    const downloaderService = new ecs.Ec2Service(this, 'DownloaderService', {
      serviceName: 'downloader',
      cluster,
      taskDefinition: downloaderTaskDefinition,
      enableExecuteCommand: true,
    });

    const downloaderTargetGroup = new elbv2.ApplicationTargetGroup(this, 'DownloaderTargetGroup', {
      targets: [downloaderService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
      healthCheck: {
        path: '/downloader/',
      },
    });

    sslListener.addTargetGroups('DownloaderTargetGroups', {
      targetGroups: [downloaderTargetGroup],
      priority: 7,
      conditions: [
        elbv2.ListenerCondition.hostHeaders(['admin-catalog.paradisec.org.au', `admin-catalog.${zoneName}`]),
        elbv2.ListenerCondition.pathPatterns(['/downloader', '/downloader/*']),
      ],
    });

    // ////////////////////////
    // Sentry Relay
    // ////////////////////////

    const sentryTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SentryTaskDefinition', {
      networkMode: ecs.NetworkMode.AWS_VPC,
    });
    acknowledgeNag(sentryTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });

    // Sentry container - not exposed externally
    sentryTaskDefinition.addContainer('SentryContainer', {
      containerName: 'sentry',
      memoryLimitMiB: 128,
      image: ecs.ContainerImage.fromRegistry('getsentry/relay'),
      portMappings: [{ name: 'sentry', containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SentryService' }),
      environment: {
        RELAY_MODE: 'proxy',
      },
    });

    // Nginx proxy container - handles path rewriting
    sentryTaskDefinition.addContainer('NginxContainer', {
      containerName: 'nginx',
      memoryLimitMiB: 64,
      image: ecs.ContainerImage.fromAsset('../docker', {
        file: 'sentry-nginx.Dockerfile',
      }),
      portMappings: [{ name: 'nginx', containerPort: 80 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SentryNginx' }),
    });

    const sentryService = new ecs.Ec2Service(this, 'SentryService', {
      serviceName: 'sentry',
      cluster,
      taskDefinition: sentryTaskDefinition,
      enableExecuteCommand: true,
    });

    const sentryTargetGroup = new elbv2.ApplicationTargetGroup(this, 'SentryTargetGroup', {
      targets: [sentryService.loadBalancerTarget({ containerName: 'nginx' })],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
      healthCheck: {
        path: '/sentry-relay/api/relay/healthcheck/live/',
      },
    });

    // ////////////////////////
    // Oni
    // ////////////////////////

    const oniTaskDefinition = new ecs.Ec2TaskDefinition(this, 'OniTaskDefinition');
    acknowledgeNag(oniTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });
    oniTaskDefinition.addContainer('OniContainer', {
      containerName: 'oni',
      memoryLimitMiB: 128,
      image: ecs.ContainerImage.fromAsset('../docker', {
        file: 'oni.Dockerfile',
        buildArgs: {
          ROCRATE_API_ENDPOINT: env === 'prod' ? 'https://admin-catalog.paradisec.org.au/' : 'https://admin-catalog.nabu-stage.paradisec.org.au',
          ROCRATE_API_CLIENTID: '8XJwJIeei7hyeikp5tT-qvhYmFbrGdqGJ0zzS4GqwIQ',
          SENTRY_ENV: env,
        },
      }),
      portMappings: [{ name: 'oni', containerPort: 80 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'OniService' }),
      environment: {
        AWS_REGION: region,
        BUCKET_NAME: catalogBucket.bucketName,
      },
    });

    const oniService = new ecs.Ec2Service(this, 'OniService', {
      serviceName: 'oni',
      cluster,
      taskDefinition: oniTaskDefinition,
      enableExecuteCommand: true,
    });

    const oniTargetGroup = new elbv2.ApplicationTargetGroup(this, 'OniTargetGroup', {
      targets: [oniService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
    });

    sslListener.addTargetGroups('OniTargetGroups', {
      targetGroups: [oniTargetGroup],
      priority: 15,
      conditions: [elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au', `catalog.${zoneName}`])],
    });

    // //////////////////////
    // Secrets
    // ////////////////////////
    const appSecrets = new secretsmanager.Secret(this, 'AppSecrets', {
      secretObjectValue: {
        recaptcha_site_key: cdk.SecretValue.unsafePlainText('secret'),
        recaptcha_secret_key: cdk.SecretValue.unsafePlainText('secret'),
        sentry_api_token: cdk.SecretValue.unsafePlainText('secret'),
        secret_key_base: cdk.SecretValue.unsafePlainText('secret'),
        datacite_user: cdk.SecretValue.unsafePlainText('secret'),
        datacite_pass: cdk.SecretValue.unsafePlainText('secret'),
      },
    });
    acknowledgeNag(appSecrets, { id: 'AwsSolutions-SMG4', reason: 'No auto rotation needed' });

    // ////////////////////////
    // App
    // ////////////////////////

    const appImage = ecs.ContainerImage.fromAsset('..', {
      file: 'Dockerfile',
      buildArgs: {
        GIT_SHA: execSync('git rev-parse HEAD').toString().trim(),
      },
    });

    if (!db.secret) {
      throw new Error('No secret found for database');
    }

    const commonAppImageOptions: ecs.ContainerDefinitionOptions = {
      image: appImage,
      environment: {
        RAILS_SERVE_STATIC_FILES: 'true', // TODO: do we need nginx in production??
        RAILS_ENV: railsEnv,
        OPENSEARCH_URL: `https://${searchDomain.domainEndpoint}`,
        NABU_CATALOG_BUCKET: catalogBucket.bucketName,
        SENTRY_DSN,
        DOI_PREFIX: '10.26278',
        DATACITE_BASE_URL: env === 'prod' ? 'https://api.datacite.org' : 'https://api.test.datacite.org',
        AWS_REGION: region,
      },
      secrets: {
        SECRET_KEY_BASE: ecs.Secret.fromSecretsManager(appSecrets, 'secret_key_base'),
        NABU_DATABASE_PASSWORD: ecs.Secret.fromSecretsManager(db.secret, 'password'),
        NABU_DATABASE_HOSTNAME: ecs.Secret.fromSecretsManager(db.secret, 'host'),
        RECAPTCHA_SITE_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'recaptcha_site_key'),
        RECAPTCHA_SECRET_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'recaptcha_secret_key'),
        SENTRY_API_TOKEN: ecs.Secret.fromSecretsManager(appSecrets, 'sentry_api_token'),
        DATACITE_USER: ecs.Secret.fromSecretsManager(appSecrets, 'datacite_user'),
        DATACITE_PASS: ecs.Secret.fromSecretsManager(appSecrets, 'datacite_pass'),
        OPENID_SIGNING_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'openid_signing_key'),
      },
    };

    const appTaskDefinition = new ecs.Ec2TaskDefinition(this, 'AppTaskDefinition');
    acknowledgeNag(appTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });
    appTaskDefinition.addContainer('AppContainer', {
      containerName: 'app',
      ...commonAppImageOptions,
      // NOTE: This is huge due to being able to show all 30000 items on the one page
      memoryLimitMiB: 4096,
      memoryReservationMiB: 1024,
      portMappings: [{ containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'AppService' }),
    });
    appTaskDefinition.addToTaskRolePolicy(
      new iam.PolicyStatement({
        actions: ['ses:SendRawEmail'],
        resources: ['*'],
      }),
    );
    appTaskDefinition.addToTaskRolePolicy(
      new iam.PolicyStatement({
        actions: ['lambda:InvokeFunction'],
        resources: [`arn:aws:lambda:${this.region}:${this.account}:function:paragest-backfill-extract-text-${env}`],
      }),
    );

    const appService = new ecs.Ec2Service(this, 'AppService', {
      serviceName: 'app',
      cluster,
      taskDefinition: appTaskDefinition,
      enableExecuteCommand: true,
      minHealthyPercent: 50,
      desiredCount: 6,
    });
    appService.enableServiceConnect();

    db.connections.allowDefaultPortFrom(autoScalingGroup, 'Allow from ECS service');
    const loadBalancer = elbv2.ApplicationLoadBalancer.fromLookup(this, 'AppAlb', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
    });
    loadBalancer.connections.allowTo(autoScalingGroup, ec2.Port.allTcp(), 'Allow from LB to ECS service');
    searchDomain.grantReadWrite(appTaskDefinition.taskRole);
    catalogBucket.grantReadWrite(appTaskDefinition.taskRole);
    // db_sync dumps prod (write) / restores staging (read) via the db-transfer/ prefix
    metaBucket.grantReadWrite(appTaskDefinition.taskRole, 'db-transfer/*');
    searchDomain.connections.allowDefaultPortFrom(autoScalingGroup, 'Allow from ECS service');

    const appTargetGroup = new elbv2.ApplicationTargetGroup(this, 'AppTargetGroup', {
      targets: [appService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
      deregistrationDelay: cdk.Duration.seconds(5),
      healthCheck: {
        path: '/up',
        interval: cdk.Duration.seconds(10),
        healthyThresholdCount: 2,
        unhealthyThresholdCount: 3,
        timeout: cdk.Duration.seconds(5),
      },
    });

    sslListener.addTargetGroups('AlbTargetGroups', {
      targetGroups: [appTargetGroup],
      priority: 20,
      conditions: [elbv2.ListenerCondition.hostHeaders(['admin-catalog.paradisec.org.au', `admin-catalog.${zoneName}`])],
    });

    sslListener.addTargetGroups('AlbTargetGroupsAPIs', {
      targetGroups: [appTargetGroup],
      priority: 8,
      conditions: [
        elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au', `catalog.${zoneName}`]),
        elbv2.ListenerCondition.pathPatterns(['/oai', '/oai/*']),
      ],
    });

    sslListener.addAction('RepositoryRedirectProd', {
      priority: 9,
      conditions: [elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au']), elbv2.ListenerCondition.pathPatterns(['/repository/*'])],
      action: elbv2.ListenerAction.redirect({
        protocol: 'HTTPS',
        host: 'admin-catalog.paradisec.org.au',
        permanent: false,
      }),
    });

    sslListener.addAction('RepositoryRedirectZone', {
      priority: 10,
      conditions: [elbv2.ListenerCondition.hostHeaders([`catalog.${zoneName}`]), elbv2.ListenerCondition.pathPatterns(['/repository/*'])],
      action: elbv2.ListenerAction.redirect({
        protocol: 'HTTPS',
        host: `admin-catalog.${zoneName}`,
        permanent: false,
      }),
    });

    // ////////////////////////
    // Jobs
    // ////////////////////////

    const jobsTaskDefinition = new ecs.Ec2TaskDefinition(this, 'JobsTaskDefinition');
    acknowledgeNag(jobsTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });
    jobsTaskDefinition.addContainer('JobsContainer', {
      containerName: 'jobs',
      ...commonAppImageOptions,
      memoryLimitMiB: 8912,
      memoryReservationMiB: 1024,
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'JobsService' }),
      command: ['bin/jobs'],
    });
    jobsTaskDefinition.addToTaskRolePolicy(
      new iam.PolicyStatement({
        actions: ['ses:SendRawEmail'],
        resources: ['*'],
      }),
    );
    searchDomain.grantReadWrite(jobsTaskDefinition.taskRole);
    catalogBucket.grantReadWrite(jobsTaskDefinition.taskRole);
    metaBucket.grantRead(jobsTaskDefinition.taskRole);
    if (env === 'prod') {
      metaDrBucket.grantRead(jobsTaskDefinition.taskRole);
    }

    const jobsService = new ecs.Ec2Service(this, 'JobsService', {
      serviceName: 'jobs',
      cluster,
      taskDefinition: jobsTaskDefinition,
      enableExecuteCommand: true,
    });
    jobsService.enableServiceConnect();

    const listener = elbv2.ApplicationListener.fromLookup(this, 'AlbListener', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
      listenerProtocol: elbv2.ApplicationProtocol.HTTP,
    });

    // TODO: Technically anyone could use this route but why would they vs just going direct?
    listener.addTargetGroups('SentryTargetGroups', {
      targetGroups: [sentryTargetGroup],
      priority: 7,
      conditions: [elbv2.ListenerCondition.pathPatterns(['/sentry-relay/*'])],
    });

    //Cloudflare validation
    listener.addAction('CloudflareDcv', {
      priority: 10,
      conditions: [elbv2.ListenerCondition.hostHeaders([`admin-catalog.${zoneName}`]), elbv2.ListenerCondition.pathPatterns([adminAcmePath])],
      action: elbv2.ListenerAction.fixedResponse(200, {
        contentType: 'text/plain',
        messageBody: adminAcmeValue,
      }),
    });

    // ////////////////////////
    // DNS
    // ////////////////////////

    new route53.CnameRecord(this, 'CatalogRecord', {
      recordName: 'catalog',
      zone,
      domainName: cloudflare,
    });

    new route53.CnameRecord(this, 'AdminCatalogRecord', {
      recordName: 'admin-catalog',
      zone,
      domainName: `admin-${cloudflare}`,
    });

    // ////////////////////////
    // SES
    // ////////////////////////

    // From
    new ses.EmailIdentity(this, 'AdminSesIdentity', {
      identity: ses.Identity.email('admin@paradisec.org.au'),
    });

    if (env === 'stage') {
      // To
      const testers = ['johnf@inodes.org', 'jodie.kell@sydney.edu.au', 'julia.miller@anu.edu.au', 'enwardy@hotmail.com', 'thien@unimelb.edu.au'];
      testers.forEach((email) => {
        new ses.EmailIdentity(this, `TesterSesIdentity-${email}`, {
          identity: ses.Identity.email(email),
        });
      });
    }

    // ////////////////////////
    // Backups (prod only)
    // ////////////////////////

    if (env === 'prod') {
      const plan = new backup.BackupPlan(this, 'BackupPlan');

      plan.addRule(
        new backup.BackupPlanRule({
          ruleName: 'Daily',
          scheduleExpression: events.Schedule.cron({ hour: '5', minute: '0' }),
          deleteAfter: cdk.Duration.days(35),
        }),
      );

      // Monthly snapshot is the offsite copy — weeks-to-months RTO makes
      // daily cross-region copies wasteful given the user's stated RPO.
      plan.addRule(
        new backup.BackupPlanRule({
          ruleName: 'Monthly1Year',
          scheduleExpression: events.Schedule.cron({ day: '1', hour: '5', minute: '0' }),
          moveToColdStorageAfter: cdk.Duration.days(30),
          deleteAfter: cdk.Duration.days(365),
          copyActions: [
            {
              destinationBackupVault: drBackupVault,
              moveToColdStorageAfter: cdk.Duration.days(30),
              deleteAfter: cdk.Duration.days(365),
            },
          ],
        }),
      );

      plan.addSelection('BackupSelection', {
        resources: [backup.BackupResource.fromRdsDatabaseInstance(db)],
      });
    }

    // ////////////////////////
    // S3 Event Handling
    // ////////////////////////

    if (env === 'prod') {
      const image = new ecrAssets.DockerImageAsset(this, 'CopyToMediafluxImage', {
        directory: 'docker/mediaflux',
      });

      const mediafluxSecrets = new secretsmanager.Secret(this, 'MediaFluxSecrets', {
        secretName: '/nabu/mediaflux',
        secretObjectValue: {
          password: cdk.SecretValue.unsafePlainText('secret'),
        },
      });
      acknowledgeNag(mediafluxSecrets, { id: 'AwsSolutions-SMG4', reason: 'No auto rotation needed' });

      // appSubnets points at the public subnets, which are shared with the ingress ALB and NLB. All
      // three are /28s and they run out of addresses first, so tasks die in PROVISIONING with
      // InsufficientFreeAddressesInSubnet — which RunTask has already reported as a success. The
      // backup workload gets the application subnets to itself instead; same TGW egress path.
      const mediafluxSubnets = ['a', 'b', 'c'].map((az, index) => {
        const subnetId = ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/private/apse2${az}-id`);
        const availabilityZone = `ap-southeast-2${az}`;
        const subnet = ec2.Subnet.fromSubnetAttributes(this, `MediafluxSubnet${index}`, { subnetId, availabilityZone });
        cdk.Annotations.of(subnet).acknowledgeWarning('@aws-cdk/aws-ec2:noSubnetRouteTableId');

        return subnet;
      });

      // Scratch space for objects too large for the 200 GiB Fargate ephemeral disk. Mount targets go
      // in the data subnets so they don't spend addresses the upload jobs need.
      const scratchFileSystem = new efs.FileSystem(this, 'MediafluxScratchFileSystem', {
        vpc,
        vpcSubnets: { subnets: dataSubnets },
        throughputMode: efs.ThroughputMode.ELASTIC,
        encrypted: true,
      });

      const scratchAccessPoint = scratchFileSystem.addAccessPoint('MediafluxScratchAccessPoint', {
        path: '/scratch',
        createAcl: { ownerUid: '0', ownerGid: '0', permissions: '0755' },
        posixUser: { uid: '0', gid: '0' },
      });

      const uploadLogGroup = new logs.LogGroup(this, 'MediafluxUploadLogGroup', {
        logGroupName: '/nabu/mediaflux-upload',
        retention: logs.RetentionDays.ONE_YEAR,
      });

      const jobRole = new iam.Role(this, 'MediafluxJobRole', {
        assumedBy: new iam.ServicePrincipal('ecs-tasks.amazonaws.com'),
      });
      catalogBucket.grantRead(jobRole);
      acknowledgeNag(jobRole, { id: 'AwsSolutions-IAM5', reason: 'Star on S3 get is fine' });
      // The denyAnonymousAccess feature flag makes CDK attach a file system policy granting only
      // ClientWrite and ClientRootAccess. A policy without ClientMount denies the mount outright, so
      // the job has to be granted it explicitly and then mount as itself (useJobRole below).
      scratchFileSystem.grantRootAccess(jobRole);

      const jobDefinition = new batch.EcsJobDefinition(this, 'MediafluxJobDefinition', {
        container: new batch.EcsFargateContainerDefinition(this, 'MediafluxJobContainer', {
          image: ecs.ContainerImage.fromDockerImageAsset(image),
          cpu: MEDIAFLUX_JOB_VCPUS,
          memory: cdk.Size.gibibytes(16),
          ephemeralStorageSize: cdk.Size.gibibytes(200),
          jobRole,
          logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'copy-to-mediaflux', logGroup: uploadLogGroup }),
          environment: {
            SENTRY_DSN,
            LARGE_OBJECT_SCRATCH_DIR: MEDIAFLUX_SCRATCH_PATH,
          },
          secrets: {
            // NOTE: This token is tied to John Ferlito's account and will need to be replaced if his account is removed
            MFLUX_TOKEN: batch.Secret.fromSecretsManager(mediafluxSecrets, 'token'),
          },
          volumes: [
            batch.EcsVolume.efs({
              name: 'mediaflux-scratch',
              fileSystem: scratchFileSystem,
              accessPointId: scratchAccessPoint.accessPointId,
              useJobRole: true,
              containerPath: MEDIAFLUX_SCRATCH_PATH,
              enableTransitEncryption: true,
            }),
          ],
        }),
        // A failed upload now goes back on the queue instead of needing a human to spot it in the
        // weekly size report. Covers the infrastructure failures as well as the transient
        // "Listening socket closed!" drops mid-transfer.
        retryAttempts: 3,
        timeout: cdk.Duration.hours(12),
      });

      const computeEnvironment = new batch.FargateComputeEnvironment(this, 'MediafluxComputeEnvironment', {
        vpc,
        vpcSubnets: { subnets: mediafluxSubnets },
        maxvCpus: MEDIAFLUX_JOB_VCPUS * MEDIAFLUX_MAX_CONCURRENT_JOBS,
      });
      scratchFileSystem.connections.allowDefaultPortFrom(computeEnvironment);

      const jobQueue = new batch.JobQueue(this, 'MediafluxJobQueue', {
        computeEnvironments: [{ computeEnvironment, order: 1 }],
      });

      const alarmTopic = new sns.Topic(this, 'MediafluxAlarmTopic', {
        displayName: 'Nabu Mediaflux backup alarms',
        enforceSSL: true,
      });
      acknowledgeNag(alarmTopic, { id: 'AwsSolutions-SNS2', reason: 'Alarm metadata only, no catalog content' });

      // Catches the case the job can never report on itself: EventBridge failing to submit the job
      // at all. Everything past submission reports to Sentry from inside the container.
      const eventDlq = new sqs.Queue(this, 'MediafluxEventDlq', {
        retentionPeriod: cdk.Duration.days(14),
        enforceSSL: true,
      });
      acknowledgeNag(eventDlq, { id: 'AwsSolutions-SQS3', reason: 'This is itself a dead letter queue' });

      new cloudwatch.Alarm(this, 'MediafluxEventDlqAlarm', {
        alarmDescription: 'An object created in the catalog bucket never made it onto the Mediaflux job queue',
        metric: eventDlq.metricApproximateNumberOfMessagesVisible(),
        threshold: 0,
        evaluationPeriods: 1,
        comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      }).addAlarmAction(new cloudwatchActions.SnsAction(alarmTopic));

      new events.Rule(this, 'S3PutEventRule', {
        description: 'Rule to queue a Mediaflux backup job on S3 put event',
        eventPattern: {
          source: ['aws.s3'],
          detailType: ['Object Created'],
          detail: {
            bucket: {
              name: [catalogBucket.bucketName],
            },
            object: {
              key: [{ prefix: '' }],
            },
          },
        },
        targets: [
          new targets.BatchJob(jobQueue.jobQueueArn, jobQueue, jobDefinition.jobDefinitionArn, jobDefinition, {
            jobName: 'copy-to-mediaflux',
            deadLetterQueue: eventDlq,
            retryAttempts: 5,
            event: events.RuleTargetInput.fromObject({
              ContainerOverrides: {
                Environment: [
                  { Name: 'S3_BUCKET', Value: events.EventField.fromPath('$.detail.bucket.name') },
                  { Name: 'S3_KEY', Value: events.EventField.fromPath('$.detail.object.key') },
                ],
              },
            }),
          }),
        ],
      });

      // A job that exhausts its retries has usually failed before the container ran, so there is no
      // code left to tell Sentry about it. Failures land in a queue rather than mailing one message
      // each: a single EFS misconfiguration produced 221 of them, which buries the signal it was
      // meant to raise. The queue keeps each failure for triage and the alarm below reports the rate.
      const jobFailureQueue = new sqs.Queue(this, 'MediafluxJobFailureQueue', {
        retentionPeriod: cdk.Duration.days(14),
        enforceSSL: true,
      });
      acknowledgeNag(jobFailureQueue, { id: 'AwsSolutions-SQS3', reason: 'Holds failures for triage, it is not a work queue' });

      new events.Rule(this, 'MediafluxJobFailureRule', {
        description: 'Record Mediaflux backup jobs that fail after exhausting their retries',
        eventPattern: {
          source: ['aws.batch'],
          detailType: ['Batch Job State Change'],
          detail: {
            status: ['FAILED'],
            jobQueue: [jobQueue.jobQueueArn],
          },
        },
        targets: [new targets.SqsQueue(jobFailureQueue)],
      });

      // Alarms notify on the transition into ALARM, so a run of failures raises one message and then
      // stays put until it recovers, however many jobs fail behind it.
      new cloudwatch.Alarm(this, 'MediafluxJobFailureAlarm', {
        alarmDescription: 'Mediaflux backup jobs are failing after exhausting their retries',
        metric: jobFailureQueue.metricNumberOfMessagesSent({
          statistic: 'Sum',
          period: cdk.Duration.minutes(15),
        }),
        threshold: 0,
        evaluationPeriods: 1,
        comparisonOperator: cloudwatch.ComparisonOperator.GREATER_THAN_THRESHOLD,
        treatMissingData: cloudwatch.TreatMissingData.NOT_BREACHING,
      }).addAlarmAction(new cloudwatchActions.SnsAction(alarmTopic));

      const cluster = new ecs.Cluster(this, 'NabuCluster', {
        vpc,
        containerInsightsV2: ecs.ContainerInsights.ENHANCED,
      });
      acknowledgeNag(cluster, {
        id: 'AwsSolutions-ECS4',
        reason: 'https://github.com/cdklabs/cdk-nag/pull/1927',
      });

      const inventoryTaskDefinition = new ecs.FargateTaskDefinition(this, 'MediafluxInventoryTaskDefinition', {
        cpu: 1024,
        memoryLimitMiB: 2048,
      });

      inventoryTaskDefinition.addContainer('MediafluxInventoryContainer', {
        containerName: 'mediaflux-inventory',
        image: ecs.ContainerImage.fromDockerImageAsset(image),
        command: ['node', '/app/inventory.ts'],
        logging: new ecs.AwsLogDriver({ streamPrefix: 'mediaflux-inventory' }),
        pseudoTerminal: true,
        environment: {
          SENTRY_DSN,
          META_BUCKET: metaBucket.bucketName,
        },
        secrets: {
          MFLUX_TOKEN: ecs.Secret.fromSecretsManager(mediafluxSecrets, 'token'),
        },
      });

      metaBucket.grantWrite(inventoryTaskDefinition.taskRole, 'mediaflux-inventory/*');
      acknowledgeNag(inventoryTaskDefinition, { id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' });

      const inventoryTask = new targets.EcsTask({
        cluster,
        taskDefinition: inventoryTaskDefinition,
        subnetSelection: { subnets: mediafluxSubnets },
      });

      new events.Rule(this, 'MediafluxInventoryScheduleRule', {
        description: 'Daily mediaflux inventory check at 18:00 UTC (04:00 AEST)',
        schedule: events.Schedule.cron({ hour: '18', minute: '0' }),
        targets: [inventoryTask],
      });
    }
    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
