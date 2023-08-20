import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as autoscaling from 'aws-cdk-lib/aws-autoscaling';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as ecsPatterns from 'aws-cdk-lib/aws-ecs-patterns';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as elbv2Target from 'aws-cdk-lib/aws-elasticloadbalancingv2-targets';
import * as iam from 'aws-cdk-lib/aws-iam';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import * as s3 from 'aws-cdk-lib/aws-s3';
import * as servicediscovery from 'aws-cdk-lib/aws-servicediscovery';
// import * as ssm from 'aws-cdk-lib/aws-ssm';

import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import { ISecret } from 'aws-cdk-lib/aws-secretsmanager';
import { SecretValue } from 'aws-cdk-lib';

import { Environment } from './types';

export class AppStack extends cdk.Stack {
  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      appName,
      // account,
      region,
      railsEnv,
      env,
      zoneName,
    } = environment;

    // ////////////////////////
    // DNS
    // ////////////////////////

    const zone = new route53.PublicHostedZone(this, 'HostedZone', {
      zoneName,
      caaAmazon: true,
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
      memoryLimitMiB: 1024,
      taskImageOptions: {
        image: ecs.ContainerImage.fromAsset('..', { file: 'docker/app.Dockerfile' }),
        containerPort: 3000,
        environment: {
          RAILS_SERVE_STATIC_FILES: 'true', // TODO: do we need nginx in production??
          RAILS_ENV: railsEnv,
          SOLR_URL: `http+srv://search.nabu/solr/${railsEnv}`,
          PROXYIST_URL: 'http+srv://proxyist.nabu',
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
      publicLoadBalancer: false,

      // Auto create a certiifcate
      domainName: `catalog.${zoneName}`,
      domainZone: zone,
      recordType: ecsPatterns.ApplicationLoadBalancedServiceRecordType.NONE,

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
      memoryLimitMiB: 1024,
      image: ecs.ContainerImage.fromAsset('..', { file: 'docker/search.Dockerfile' }),
      portMappings: [{ containerPort: 8983 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SearchService' }),
      ulimits: [
        { name: ecs.UlimitName.NOFILE, softLimit: 65536, hardLimit: 65536 * 2 },
      ],
    });

    new ecs.Ec2Service(this, 'SearchService', {
      serviceName: 'search',
      cluster,
      taskDefinition: searchTaskDefinition,
      enableExecuteCommand: true,
      cloudMapOptions: {
        name: 'search',
        cloudMapNamespace: dnsNamespace,
      },
    });

    // ////////////////////////
    // Network Load Balancer
    // ////////////////////////

    const nlb = new elbv2.NetworkLoadBalancer(this, 'NLB', {
      vpc,
      vpcSubnets: {
        // subnets: appSubnets,
        subnetType: ec2.SubnetType.PUBLIC,
      },
      internetFacing: true,
    });

    const sslListener = nlb.addListener('NLBListener443', {
      port: 443,
    });
    const sslTarget = sslListener.addTargets('NLBTarget443', {
      port: 443,
      targets: [new elbv2Target.AlbTarget(app.loadBalancer, 443)],
    });
    sslTarget.node.addDependency(app.listener);

    const listener = nlb.addListener('NLBListener', {
      port: 80,
    });
    const target = listener.addTargets('NLBTarget', {
      port: 80,
      targets: [new elbv2Target.AlbTarget(app.loadBalancer, 80)],
    });
    target.node.addDependency(app.listener);

    // ////////////////////////
    // DNS
    // ////////////////////////

    new route53.ARecord(this, 'ARecord', {
      recordName: 'catalog',
      zone,
      target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(nlb)),
    });

    // ////////////////////////
    // Meta Bucket
    // ////////////////////////
    const metaBucket = new s3.Bucket(this, 'MetaBucket', {
      bucketName: `${appName}-meta-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      enforceSSL: true,
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // ////////////////////////
    // Catalog bucket
    // ////////////////////////

    const catalogBucket = new s3.Bucket(this, 'CatalogBucket', {
      bucketName: `${appName}-catalog-${env}`,
      encryption: s3.BucketEncryption.S3_MANAGED,
      enforceSSL: true,
      // TODO: Do we want tiering?
      // intelligentTieringConfigurations: [ ],
      // TODO: Decide on lifecycle rules
      // lifecycleRules: [],
      inventories: [{
        destination: {
          bucket: metaBucket,
          prefix: 'inventories/catalog',
        },
        frequency: s3.InventoryFrequency.DAILY,
        includeObjectVersions: s3.InventoryObjectVersion.CURRENT,
      }],
      removalPolicy: cdk.RemovalPolicy.RETAIN,
    });

    // Create a temp user for the migration
    const tempUser = iam.User.fromUserName(this, 's3TempUser', 's3-migration-temp');
    catalogBucket.grantReadWrite(tempUser);

    // ////////////////////////
    // Proxyist
    // ////////////////////////

    const proxyistTaskDefinition = new ecs.Ec2TaskDefinition(this, 'ProxyistTaskDefinition');
    proxyistTaskDefinition.addContainer('ProxyistContainer', {
      memoryLimitMiB: 512,
      image: ecs.ContainerImage.fromAsset('..', { file: 'docker/proxyist.Dockerfile' }),
      portMappings: [{ containerPort: 3000 }],
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
      cloudMapOptions: {
        name: 'proxyist',
        cloudMapNamespace: dnsNamespace,
      },
    });
  }
}
