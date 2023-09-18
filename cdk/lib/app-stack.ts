import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as ssm from 'aws-cdk-lib/aws-ssm';

import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { ISecret } from 'aws-cdk-lib/aws-secretsmanager';
import { SecretValue } from 'aws-cdk-lib';

import { AppProps } from './types';

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, appProps: AppProps, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      region,
      railsEnv,
      // env,
      zoneName,

      catalogBucket,
      zone,
    } = appProps;

    // ////////////////////////
    // Network
    // ////////////////////////

    const vpc = ec2.Vpc.fromLookup(this, 'VPC', { vpcId: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/vpc-id') });

    const dataSubnetIds = ['a', 'b', 'c'].map((az) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/isolated/apse2${az}-id`));
    const dataSubnets = dataSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `DataSubnet${index}`, { subnetId }));

    const appSubnetIds = ['a', 'b', 'c'].map((az) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/public/apse2${az}-id`));
    const appSubnets = appSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `AppSubnet${index}`, { subnetId }));

    // ////////////////////////
    // Database
    // ////////////////////////

    const db = new rds.DatabaseInstance(this, 'RdsInstance', {
      engine: rds.DatabaseInstanceEngine.mysql({ version: rds.MysqlEngineVersion.VER_8_0 }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO),
      credentials: rds.Credentials.fromGeneratedSecret('nabu'),
      databaseName: 'nabu',
      vpc,
      vpcSubnets: {
        subnets: dataSubnets,
      },
    });

    // ////////////////////////
    // ECS Cluster
    // ////////////////////////

    const cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: appName,
      vpc,
    });
    cluster.addDefaultCloudMapNamespace({
      name: 'nabu',
      useForServiceConnect: true,
    });

    const autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'EcsASG', {
      vpc,
      vpcSubnets: {
        subnets: appSubnets,
      },

      instanceType: new ec2.InstanceType('c6a.xlarge'),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),

      minCapacity: 1,
      maxCapacity: 1,

      // keyName: 'nabu',
    });
    // needed by service connect
    autoScalingGroup.addToRolePolicy(new iam.PolicyStatement({
      actions: ['ecs:Poll'],
      resources: ['*'],
    }));

    const capacityProvider = new ecs.AsgCapacityProvider(this, 'EcsAsgCapacityProvider', {
      autoScalingGroup,
    });
    cluster.addAsgCapacityProvider(capacityProvider);

    // ////////////////////////
    // Search
    // ////////////////////////

    const searchTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SearchTaskDefinition', {
      volumes: [{
        name: 'solr-data',
        dockerVolumeConfiguration: {
          scope: ecs.Scope.SHARED,
          autoprovision: true,
          driver: 'local',
        },
      }],
    });
    const searchContainer = searchTaskDefinition.addContainer('SearchContainer', {
      memoryLimitMiB: 1024,
      image: ecs.ContainerImage.fromAsset('..', { file: 'docker/search.Dockerfile' }),
      portMappings: [{ name: 'search', containerPort: 8983 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SearchService' }),
      ulimits: [
        { name: ecs.UlimitName.NOFILE, softLimit: 65536, hardLimit: 65536 * 2 },
      ],
    });
    searchContainer.addMountPoints({
      containerPath: `/var/solr/mnt/${railsEnv}`,
      readOnly: false,
      sourceVolume: 'solr-data',
    });

    new ecs.Ec2Service(this, 'SearchService', {
      serviceName: 'search',
      cluster,
      taskDefinition: searchTaskDefinition,
      enableExecuteCommand: true,
      serviceConnectConfiguration: {
        logDriver: ecs.LogDrivers.awsLogs({
          streamPrefix: 'sc-traffic',
        }),
        services: [{
          portMappingName: 'search',
        }],
      },
    });

    // ////////////////////////
    // Proxyist
    // ////////////////////////

    const proxyistTaskDefinition = new ecs.Ec2TaskDefinition(this, 'ProxyistTaskDefinition');
    proxyistTaskDefinition.addContainer('ProxyistContainer', {
      memoryLimitMiB: 512,
      image: ecs.ContainerImage.fromAsset('..', { file: 'docker/proxyist.Dockerfile' }),
      portMappings: [{ name: 'proxyist', containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'ProxyistService' }),
      environment: {
        AWS_REGION: region,
        BUCKET_NAME: catalogBucket.bucketName,
      },
    });
    catalogBucket.grantReadWrite(proxyistTaskDefinition.taskRole);

    new ecs.Ec2Service(this, 'ProxyistService', {
      serviceName: 'proxyist',
      cluster,
      taskDefinition: proxyistTaskDefinition,
      enableExecuteCommand: true,
      serviceConnectConfiguration: {
        logDriver: ecs.LogDrivers.awsLogs({
          streamPrefix: 'sc-traffic',
        }),
        services: [{
          portMappingName: 'proxyist',
        }],
      },
    });

    // //////////////////////
    // Secrets
    // ////////////////////////
    const appSecrets = new secretsmanager.Secret(this, 'AppSecrets', {
      secretObjectValue: {
        recaptcha_site_key: SecretValue.unsafePlainText('secret'),
        recaptcha_secret_key: SecretValue.unsafePlainText('secret'),
        sentry_api_token: SecretValue.unsafePlainText('secret'),
        secret_key_base: SecretValue.unsafePlainText('secret'),
        datacite_user: SecretValue.unsafePlainText('secret'),
        datacite_pass: SecretValue.unsafePlainText('secret'),
      },
    });

    // ////////////////////////
    // App
    // ////////////////////////

    const appImage = ecs.ContainerImage.fromAsset('..', { file: 'docker/app.Dockerfile' });
    const commonAppImageOptions: ecs.ContainerDefinitionOptions = {
      image: appImage,
      memoryLimitMiB: 1024,
      environment: {
        RAILS_SERVE_STATIC_FILES: 'true', // TODO: do we need nginx in production??
        RAILS_ENV: railsEnv,
        SOLR_URL: `http://search.nabu:8983/solr/${railsEnv}`,
        PROXYIST_URL: 'http://proxyist.nabu:3000',
        SENTRY_DSN: 'https://aa8f28b06df84f358949b927e85a924e@o4504801902985216.ingest.sentry.io/4504801910980608',
        DOI_PREFIX: '10.26278',
        DATACITE_BASE_URL: 'https://mds.datacite.org',
      },
      secrets: {
        SECRET_KEY_BASE: ecs.Secret.fromSecretsManager(appSecrets, 'secret_key_base'),
        NABU_DATABASE_PASSWORD: ecs.Secret.fromSecretsManager(db.secret as ISecret, 'password'),
        NABU_DATABASE_HOSTNAME: ecs.Secret.fromSecretsManager(db.secret as ISecret, 'host'),
        RECAPTCHA_SITE_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'recaptcha_site_key'),
        RECAPTCHA_SECRET_KEY: ecs.Secret.fromSecretsManager(appSecrets, 'recaptcha_secret_key'),
        SENTRY_API_TOKEN: ecs.Secret.fromSecretsManager(appSecrets, 'sentry_api_token'),
        DATACITE_USER: ecs.Secret.fromSecretsManager(appSecrets, 'datacite_user'),
        DATACITE_PASS: ecs.Secret.fromSecretsManager(appSecrets, 'datacite_pass'),
      },
    };

    const appTaskDefinition = new ecs.Ec2TaskDefinition(this, 'AppTaskDefinition');
    appTaskDefinition.addContainer('AppContainer', {
      ...commonAppImageOptions,
      portMappings: [{ containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'AppService' }),
    });

    const appService = new ecs.Ec2Service(this, 'AppService', {
      serviceName: 'app',
      cluster,
      taskDefinition: appTaskDefinition,
      enableExecuteCommand: true,
    });
    appService.enableServiceConnect();

    db.connections.allowDefaultPortFrom(autoScalingGroup, 'Allow from ECS service');
    const loadBalancer = elbv2.ApplicationLoadBalancer.fromLookup(this, 'AppAlb', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
    });
    loadBalancer.connections.allowTo(autoScalingGroup, ec2.Port.allTcp(), 'Allow from LB to ECS service');

    // ////////////////////////
    // Jobs
    // ////////////////////////

    const jobsTaskDefinition = new ecs.Ec2TaskDefinition(this, 'JobsTaskDefinition');
    jobsTaskDefinition.addContainer('JobsContainer', {
      ...commonAppImageOptions,
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'JobsService' }),
      command: ['bin/delayed_job', 'run'],
    });

    new ecs.Ec2Service(this, 'JobsService', {
      serviceName: 'jobs',
      cluster,
      taskDefinition: jobsTaskDefinition,
      enableExecuteCommand: true,
    });

    // ////////////////////////
    // Application Load Balancer
    // ////////////////////////

    const sslListener = elbv2.ApplicationListener.fromLookup(this, 'AlbSslListener', {
      loadBalancerArn: ssm.StringParameter.valueFromLookup(this, '/usyd/resources/application-load-balancer/application/arn'),
      listenerProtocol: elbv2.ApplicationProtocol.HTTPS,
    });
    const targetGroup = new elbv2.ApplicationTargetGroup(this, 'AppTargetGroup', {
      targets: [appService],
      vpc,
      protocol: elbv2.ApplicationProtocol.HTTP,
    });

    sslListener.addTargetGroups('AlbTargetGroups', {
      targetGroups: [targetGroup],
      priority: 10,
      conditions: [
        elbv2.ListenerCondition.hostHeaders(['catalog.paradisec.org.au', `catalog.${zoneName}`]),
      ],
    });

    // ////////////////////////
    // DNS
    // ////////////////////////

    new route53.CnameRecord(this, 'CatalogRecord', {
      recordName: 'catalog',
      zone,
      domainName: ssm.StringParameter.valueForStringParameter(this, '/usyd/resources/application-load-balancer/ingress/dns'),
    });
  }
}
