import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
// import * as ssm from 'aws-cdk-lib/aws-ssm';

import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { ISecret } from 'aws-cdk-lib/aws-secretsmanager';
import { SecretValue } from 'aws-cdk-lib';

export type Environment = {
  readonly appName: string,
  readonly region: string,
  readonly env: string,
  readonly railsEnv: string,
  readonly branchNames: string[],
  readonly account: string,
  readonly zoneName: string,
};

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      // account,
      // region,
      railsEnv,
      // env,
      zoneName,
    } = environment;

    // ////////////////////////
    // DNS
    // ////////////////////////

    new route53.HostedZone(this, 'HostedZone', {
      zoneName,
    });

    const tempZone = new route53.HostedZone(this, 'HostedZoneTemp', {
      zoneName: 'nabu.inodes.dev',
    });

    // Network
    // ////////////////////////
    // const vpc = ec2.Vpc.fromLookup(this, 'VPC', { vpcName: `${account}-${region}-vpc` });
    const vpc = ec2.Vpc.fromLookup(this, 'VPC', { vpcName: 'nabu-dev-temp-vpc' });

    // const dataSubnetIds = ['a', 'b', 'c'].map((az) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/isolated/apse2${az}-id`));
    // const dataSubnets = dataSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `DataSubnet${index}`, { subnetId }));
    //
    // const appSubnetIds = ['a', 'b', 'c'].map((az) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/public/apse2${az}-id`));
    // const appSubnets = appSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `AppSubnet${index}`, { subnetId }));

    // ////////////////////////
    // Service Discovery
    // ////////////////////////

    const dnsNamespace = new servicediscovery.PrivateDnsNamespace(this, 'DnsNamespace', {
      name: 'nabu',
      vpc,
      description: 'Nabu Container namespace',
    });

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
        // subnets: dataSubnets,
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      },
    });

    // ////////////////////////
    // ECS Cluster
    // ////////////////////////

    const cluster = new ecs.Cluster(this, 'Cluster', {
      clusterName: appName,
      vpc,
    });

    const autoScalingGroup = new autoscaling.AutoScalingGroup(this, 'EcsASG', {
      vpc,
      vpcSubnets: {
        // subnets: appSubnets,
        subnetType: ec2.SubnetType.PUBLIC,
      },

      instanceType: new ec2.InstanceType('c6a.xlarge'),
      machineImage: ecs.EcsOptimizedImage.amazonLinux2(),

      minCapacity: 1,
      maxCapacity: 2,
      associatePublicIpAddress: true,
    });

    const capacityProvider = new ecs.AsgCapacityProvider(this, 'EcsAsgCapacityProvider', {
      autoScalingGroup,
    });
    cluster.addAsgCapacityProvider(capacityProvider);

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

    const app = new ecsPatterns.ApplicationLoadBalancedEc2Service(this, 'AppService', {
      serviceName: 'app',
      cluster,
      memoryLimitMiB: 512,
      taskImageOptions: {
        image: ecs.ContainerImage.fromAsset('..', { file: 'docker/app.Dockerfile' }),
        containerPort: 3000,
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
      },

      // LB config
      protocol: elbv2.ApplicationProtocol.HTTPS,
      redirectHTTP: true,

      // Auto create a certiifcate
      domainName: 'catalog.nabu.inodes.dev',
      domainZone: tempZone,

      enableExecuteCommand: true,
    });
    app.targetGroup.configureHealthCheck({
      healthyHttpCodes: '200,301',
    });

    db.connections.allowDefaultPortFrom(autoScalingGroup, 'Allow from ECS service');
    app.loadBalancer.connections.allowTo(autoScalingGroup, ec2.Port.allTcp(), 'Allow from LB to ECS service');

    // ////////////////////////
    // Search
    // ////////////////////////

    const searchTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SearchTaskDefinition');
    searchTaskDefinition.addContainer('SearchContainer', {
      memoryLimitMiB: 512,
      image: ecs.ContainerImage.fromAsset('..', { file: 'docker/search.Dockerfile' }),
      portMappings: [{ containerPort: 8983 }],
    });

    new ecs.Ec2Service(this, 'SearchService', {
      cluster,
      taskDefinition: searchTaskDefinition,
      cloudMapOptions: {
        name: 'search',
        cloudMapNamespace: dnsNamespace,
      },
    });
  }
}
