import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as ssm from 'aws-cdk-lib/aws-ssm';

import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { ISecret } from 'aws-cdk-lib/aws-secretsmanager';
import { SecretValue } from 'aws-cdk-lib';

export type Environment = {
  readonly appName: string,
  readonly region: string,
  readonly env: string,
  readonly railsEnv: string,
  readonly branchName: string,
  readonly account: string,
  readonly zoneName: string,
};

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      account,
      region,
      railsEnv,
      zoneName,
    } = environment;

    // ////////////////////////
    // DNS
    // ////////////////////////

    const zone = new route53.HostedZone(this, 'HostedZone', {
      zoneName,
    });

    // ////////////////////////
    // Network
    // ////////////////////////
    const vpc = ec2.Vpc.fromLookup(this, 'VPC', { vpcName: `${account}-${region}-vpc` });

    // ////////////////////////
    // Service Discovery
    // ////////////////////////

    const dnsNamespace = new servicediscovery.PrivateDnsNamespace(this, 'DnsNamespace', {
      name: 'nabu',
      vpc,
      description: 'Nabu Container namespace',
    });

    const dataSubnetIds = ['a', 'b', 'c'].map((zone) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/isolated/apse2${zone}-id`));
    const dataSubnets = dataSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `DataSubnet${index}`, { subnetId }));

    const appSubnetIds = ['a', 'b', 'c'].map((zone) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/public/apse2${zone}-id`));
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
      vpc,
    });

    const autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'EcsASG', {
      vpc,
      vpcSubnets: {
        subnets: appSubnets,
      },

      instanceType: new ec2.InstanceType('c6a.xlarge'),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),

      minCapacity: 1,
      maxCapacity: 2,
      // desiredCapacity: 1,
    });

    const capacityProvider = new ecs.AsgCapacityProvider(this, 'EcsAsgCapacityProvider', {
      autoScalingGroup,
    });
    cluster.addAsgCapacityProvider(capacityProvider);

    // ////////////////////////
    // Search
    // ////////////////////////

    const searchTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SearchTaskDefinition', {
      networkMode: ecs.NetworkMode.AWS_VPC,
    });

    const searchImage = ecs.ContainerImage.fromAsset('..', { file: 'docker/search.Dockerfile' });

    searchTaskDefinition.addContainer('SearchContainer', {
      memoryLimitMiB: 512,
      image: searchImage,
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SearchContainer' }),
    });

    const searchService = new ecs.Ec2Service(this, 'SearchService', {
      cluster,
      taskDefinition: searchTaskDefinition,
      cloudMapOptions: {
        name: 'search',
        cloudMapNamespace: dnsNamespace,
        dnsRecordType: servicediscovery.DnsRecordType.A,
      },
    });

    // ////////////////////////
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

    const appTaskDefinition = new ecs.Ec2TaskDefinition(this, 'AppTaskDefinition', {
      networkMode: ecs.NetworkMode.AWS_VPC, // NOTE: We need t use A records for service discovery and that us only supported in AWS_VPC mode
    });
    const appImage = ecs.ContainerImage.fromAsset('..', { file: 'docker/app.Dockerfile' });

    const appArgs = {
      image: appImage,
      memoryLimitMiB: 512,
      environment: {
        RAILS_SERVE_STATIC_FILES: 'true', // TODO: do we need nginx in production??
        RAILS_ENV: railsEnv,
        SOLR_URL: `http://search.nabu:8983/solr/${railsEnv}`,
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

    appTaskDefinition.addContainer('AppContainer', {
      portMappings: [{ containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'AppContainer' }),
      ...appArgs,
    });

    const appService = new ecs.Ec2Service(this, 'AppService', {
      cluster,
      vpcSubnets: {
        subnets: appSubnets,
      },
      taskDefinition: appTaskDefinition,
      enableExecuteCommand: true,
    });
    appService.connections.allowToDefaultPort(db);
    appService.connections.allowTo(searchService, new ec2.Port({
      fromPort: 8983,
      toPort: 8983,
      protocol: ec2.Protocol.TCP,
      stringRepresentation: 'Solr 8983',
    }));

    const appLb = new elbv2.ApplicationLoadBalancer(this, 'AppLoadBalancer', {
      vpc,
      vpcSubnets: {
        subnets: appSubnets,
      },
      // internetFacing: true,
    });

    const appListener = appLb.addListener('AppListener', {
      port: 80,
    });

    appListener.addTargets('ECS', {
      port: 80,
      targets: [appService],
      healthCheck: {
        healthyHttpCodes: '200,301',
      },
    });

    // // ////////////////////////
    // // Utility Tasks
    // // ////////////////////////
    //
    // const dbMigrateDefinition = new ecs.Ec2TaskDefinition(this, 'DbMigrateDefinition', { networkMode: ecs.NetworkMode.AWS_VPC });
    // dbMigrateDefinition.addContainer('DbMigrateContainer', {
    //   command: ['bin/rails', 'db:migrate'],
    //   logging: new ecs.AwsLogDriver({ streamPrefix: 'DbMigrate' }),
    //   ...appArgs,
    // });
    //
    // const reindexDefinition = new ecs.Ec2TaskDefinition(this, 'ReindexDefinition', { networkMode: ecs.NetworkMode.AWS_VPC });
    // reindexDefinition.addContainer('ReIndexContainer', {
    //   command: ['bin/rails', 'sunspot:reindex'],
    //   logging: new ecs.AwsLogDriver({ streamPrefix: 'SunspotReindex' }),
    //   ...appArgs,
    // });
    //
    // // // ////////////////////////
    // // DNS Records
    // // ////////////////////////
    //
    // new route53.ARecord(this, 'Alias', {
    //   recordName: 'catalog',
    //   zone,
    //   target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(appLb)),
    // });
    // new route53.AaaaRecord(this, 'AliasAAAA', {
    //   recordName: 'catalog',
    //   zone,
    //   target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(appLb)),
    // });
  }
}
