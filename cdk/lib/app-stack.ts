import { execSync } from 'node:child_process';

import * as cdk from 'aws-cdk-lib';
import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as backup from 'aws-cdk-lib/aws-backup';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecrAssets from 'aws-cdk-lib/aws-ecr-assets';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as events from 'aws-cdk-lib/aws-events';
import * as targets from 'aws-cdk-lib/aws-events-targets';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as opensearch from 'aws-cdk-lib/aws-opensearchservice';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as ses from 'aws-cdk-lib/aws-ses';
import * as ssm from 'aws-cdk-lib/aws-ssm';
import { NagSuppressions } from 'cdk-nag';
import type { Construct } from 'constructs';

import type { AppProps } from './types';

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
      zone,
      //catalogCertificate,
      adminCertificate,
      tempCertificate,
      cloudflare,
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
    NagSuppressions.addResourceSuppressions(
      db,
      [
        { id: 'AwsSolutions-RDS3', reason: 'Single AZ app, HA not needed' },
        { id: 'AwsSolutions-RDS11', reason: 'Standard port is fine' },
        { id: 'AwsSolutions-SMG4', reason: "Rails doesn't support rotation" },
        { id: 'AwsSolutions-RDS2', reason: 'FIXME: We should have encryption' }, // FIXME: We should really fix this
      ],
      true,
    );

    // ////////////////////////
    // Search
    // ////////////////////////
    const searchDomain = new opensearch.Domain(this, 'SearchDomain', {
      capacity: {
        dataNodeInstanceType: 'c6g.xlarge.search', // t3's have some limitations
        dataNodes: 3,
        multiAzWithStandbyEnabled: false, // We don't need that much HA
      },
      ebs: {
        volumeSize: 20,
        volumeType: ec2.EbsDeviceVolumeType.GP3,
        throughput: 125, // These are the minimums
        iops: 3000, // These are the minimums
      },
      version: opensearch.EngineVersion.OPENSEARCH_2_11,
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
    NagSuppressions.addResourceSuppressions(searchDomain, [
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
    ]);

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
    NagSuppressions.addResourceSuppressions(cluster, [
      {
        id: 'AwsSolutions-ECS4',
        reason: 'https://github.com/cdklabs/cdk-nag/pull/1927',
      },
    ]);

    const autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'EcsASG', {
      vpc,
      vpcSubnets: {
        subnets: appSubnets,
      },

      instanceType: new ec2.InstanceType('m6a.xlarge'),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),

      minCapacity: 1,
      maxCapacity: 1,
      requireImdsv2: true,

      // keyName: 'nabu',
    });
    NagSuppressions.addResourceSuppressions(autoScalingGroup, [
      {
        id: 'AwsSolutions-EC26',
        reason: 'EBS coume already encrypted due to AMI defaults',
      },
      {
        id: 'AwsSolutions-AS3',
        reason: 'We can live without the other notifications',
      },
    ]);
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
    // Viewer
    // ////////////////////////

    const viewerTaskDefinition = new ecs.Ec2TaskDefinition(this, 'ViewerTaskDefinition');
    NagSuppressions.addResourceSuppressions(viewerTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);
    viewerTaskDefinition.addContainer('ViewerContainer', {
      containerName: 'viewer',
      memoryLimitMiB: 128,
      image: ecs.ContainerImage.fromAsset('..', {
        file: 'docker/viewer.Dockerfile',
      }),
      portMappings: [{ name: 'viewer', containerPort: 80 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'ViewerService' }),
      environment: {
        AWS_REGION: region,
        BUCKET_NAME: catalogBucket.bucketName,
      },
    });

    const viewerService = new ecs.Ec2Service(this, 'ViewerService', {
      serviceName: 'viewer',
      cluster,
      taskDefinition: viewerTaskDefinition,
      enableExecuteCommand: true,
    });

    // ////////////////////////
    // Sentry Relay
    // ////////////////////////

    const sentryTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SentryTaskDefinition', {
      networkMode: ecs.NetworkMode.AWS_VPC,
    });
    NagSuppressions.addResourceSuppressions(sentryTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);

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
      image: ecs.ContainerImage.fromAsset('..', {
        file: 'docker/sentry-nginx.Dockerfile',
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

    // ////////////////////////
    // Oni
    // ////////////////////////

    const oniTaskDefinition = new ecs.Ec2TaskDefinition(this, 'OniTaskDefinition');
    NagSuppressions.addResourceSuppressions(oniTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);
    oniTaskDefinition.addContainer('OniContainer', {
      containerName: 'oni',
      memoryLimitMiB: 128,
      image: ecs.ContainerImage.fromAsset('..', {
        file: 'docker/oni.Dockerfile',
        buildArgs: {
          ROCRATE_API_ENDPOINT: env === 'prod' ? 'https://catalog.paradisec.org.au/' : 'https://catalog.nabu-stage.paradisec.org.au',
          ROCRATE_API_CLIENTID: env === 'prod' ? '8XJwJIeei7hyeikp5tT-qvhYmFbrGdqGJ0zzS4GqwIQ' : '4MphZMvjuOYYN90U17lwAtDczQKScp52BLUPD63aQBk',
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
    NagSuppressions.addResourceSuppressions(appSecrets, [{ id: 'AwsSolutions-SMG4', reason: 'No auto rotation needed' }]);

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
        SENTRY_DSN: 'https://aa8f28b06df84f358949b927e85a924e@o4504801902985216.ingest.sentry.io/4504801910980608',
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
    NagSuppressions.addResourceSuppressions(appTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);
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
    searchDomain.connections.allowDefaultPortFrom(autoScalingGroup, 'Allow from ECS service');

    // ////////////////////////
    // Jobs
    // ////////////////////////

    const jobsTaskDefinition = new ecs.Ec2TaskDefinition(this, 'JobsTaskDefinition');
    NagSuppressions.addResourceSuppressions(jobsTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);
    jobsTaskDefinition.addContainer('JobsContainer', {
      containerName: 'jobs',
      ...commonAppImageOptions,
      memoryLimitMiB: 1024,
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

    const jobsService = new ecs.Ec2Service(this, 'JobsService', {
      serviceName: 'jobs',
      cluster,
      taskDefinition: jobsTaskDefinition,
      enableExecuteCommand: true,
    });
    jobsService.enableServiceConnect();

    if (env === 'prod') {
      const cronTaskDefinition = new ecs.Ec2TaskDefinition(this, 'CronTaskDefinition');
      NagSuppressions.addResourceSuppressions(cronTaskDefinition, [{ id: 'AwsSolutions-ECS2', reason: 'We are fine with env variables' }]);
      cronTaskDefinition.addContainer('CronContainer', {
        containerName: 'cron',
        ...commonAppImageOptions,
        memoryReservationMiB: 128,
        logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'CronService' }),
        command: ['bundle', 'exec', 'cron-worker/cron.rb'],
      });
      cronTaskDefinition.addToTaskRolePolicy(
        new iam.PolicyStatement({
          actions: ['ses:SendEmail', 'ses:SendRawEmail'],
          resources: ['*'],
        }),
      );

      catalogBucket.grantReadWrite(cronTaskDefinition.taskRole);
      metaBucket.grantRead(cronTaskDefinition.taskRole);
      metaDrBucket.grantRead(cronTaskDefinition.taskRole);
      searchDomain.grantReadWrite(cronTaskDefinition.taskRole);

      const cronService = new ecs.Ec2Service(this, 'CronService', {
        serviceName: 'cron',
        cluster,
        taskDefinition: cronTaskDefinition,
        enableExecuteCommand: true,
      });
      cronService.enableServiceConnect();
    }

    // ////////////////////////
    // Application Load Balancer
    // ////////////////////////

    const sslListener = elbv2.ApplicationListener.fromLookup(this, 'AlbSslListener', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
      listenerProtocol: elbv2.ApplicationProtocol.HTTPS,
    });
    // sslListener.addCertificates('CatalogCert', [elbv2.ListenerCertificate.fromArn(catalogCertificate.certificateArn)]);
    sslListener.addCertificates('AdminCert', [elbv2.ListenerCertificate.fromArn(adminCertificate.certificateArn)]);
    if (env === 'prod') {
      sslListener.addCertificates('TempCatalogCert', [elbv2.ListenerCertificate.fromArn(tempCertificate.certificateArn)]);
    }

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
      priority: 10,
      conditions: [elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au', `catalog.${zoneName}`])],
    });

    const viewerTargetGroup = new elbv2.ApplicationTargetGroup(this, 'ViewerTargetGroup', {
      targets: [viewerService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
    });

    sslListener.addTargetGroups('ViewerTargetGroups', {
      targetGroups: [viewerTargetGroup],
      priority: 5,
      conditions: [
        elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au', `catalog.${zoneName}`]),
        elbv2.ListenerCondition.pathPatterns(['/viewer/*']),
      ],
    });

    const sentryTargetGroup = new elbv2.ApplicationTargetGroup(this, 'SentryTargetGroup', {
      targets: [sentryService.loadBalancerTarget({ containerName: 'nginx' })],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
      healthCheck: {
        path: '/sentry-relay/api/relay/healthcheck/live/',
      },
    });

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

    const oniTargetGroup = new elbv2.ApplicationTargetGroup(this, 'OniTargetGroup', {
      targets: [oniService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
    });

    sslListener.addTargetGroups('OniTargetGroups', {
      targetGroups: [oniTargetGroup],
      priority: 6,
      conditions: [elbv2.ListenerCondition.hostHeaders(['admin.catalog.paradisec.org.au', `admin.catalog.${zoneName}`])],
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
      recordName: 'admin.catalog',
      zone,
      domainName: `admin.${cloudflare}`,
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
    // Backups
    // ////////////////////////

    const plan = backup.BackupPlan.dailyMonthly1YearRetention(this, 'BackupPlan');

    plan.addSelection('BackupSelection', {
      resources: [backup.BackupResource.fromRdsDatabaseInstance(db)],
    });

    // ////////////////////////
    // S3 Event Handling
    // ////////////////////////

    if (env === 'prod') {
      const image = new ecrAssets.DockerImageAsset(this, 'CopyToMediafluxImage', {
        directory: 'docker/mediaflux',
      });

      const taskDefinition = new ecs.FargateTaskDefinition(this, 'CopyToMediaFluxTaskDefinition', {
        cpu: 16384,
        memoryLimitMiB: 32768,
        ephemeralStorageGiB: 200,
      });
      NagSuppressions.addResourceSuppressions(searchDomain, [{ id: 'AwsSolutions-IAM5', reason: 'Star on S3 get is fine' }]);

      const mediafluxSecrets = new secretsmanager.Secret(this, 'MediaFluxSecrets', {
        secretName: '/nabu/mediaflux',
        secretObjectValue: {
          username: cdk.SecretValue.unsafePlainText('secret'),
          password: cdk.SecretValue.unsafePlainText('secret'),
        },
      });
      NagSuppressions.addResourceSuppressions(mediafluxSecrets, [{ id: 'AwsSolutions-SMG4', reason: 'No auto rotation needed' }]);

      taskDefinition.addContainer('MediafluxContainer', {
        containerName: 'mediaflux',
        image: ecs.ContainerImage.fromDockerImageAsset(image),
        logging: new ecs.AwsLogDriver({ streamPrefix: 'copy-to-mediaflux' }),
        pseudoTerminal: true,
        secrets: {
          MFLUX_USER: ecs.Secret.fromSecretsManager(mediafluxSecrets, 'username'),
          // NOTE: This token is tied to John Ferlito's account and will need to be replaced if his account is removed
          MFLUX_TOKEN: ecs.Secret.fromSecretsManager(mediafluxSecrets, 'token'),
        },
      });
      catalogBucket.grantRead(taskDefinition.taskRole);

      const cluster = new ecs.Cluster(this, 'NabuCluster', {
        vpc,
        containerInsightsV2: ecs.ContainerInsights.ENHANCED,
      });
      NagSuppressions.addResourceSuppressions(cluster, [
        {
          id: 'AwsSolutions-ECS4',
          reason: 'https://github.com/cdklabs/cdk-nag/pull/1927',
        },
      ]);

      const mediaFluxTask = new targets.EcsTask({
        cluster,
        enableExecuteCommand: true,
        subnetSelection: {
          subnets: appSubnets,
        },
        taskDefinition,
        containerOverrides: [
          {
            containerName: 'MediafluxContainer',
            environment: [
              {
                name: 'S3_BUCKET',
                value: events.EventField.fromPath('$.detail.bucket.name'),
              },
              {
                name: 'S3_KEY',
                value: events.EventField.fromPath('$.detail.object.key'),
              },
            ],
          },
        ],
      });

      new events.Rule(this, 'S3PutEventRule', {
        description: 'Rule to trigger Fargate task on S3 put event',
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
        targets: [mediaFluxTask],
      });
    }
    cdk.Tags.of(this).add('uni:billing:application', 'para');
  }
}
