import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as acm from 'aws-cdk-lib/aws-certificatemanager';
import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as ecs from 'aws-cdk-lib/aws-ecs';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as rds from 'aws-cdk-lib/aws-rds';
import * as route53 from 'aws-cdk-lib/aws-route53';
import * as targets from 'aws-cdk-lib/aws-route53-targets';
import { ISecret } from 'aws-cdk-lib/aws-secretsmanager';

type Params = {
  domainName: string,
  zoneName: string,
}

export class CdkStack extends cdk.Stack {
  constructor(scope: Construct, id: string, params: Params, props?: cdk.StackProps) {
    super(scope, id, props);

    const {
      domainName,
      zoneName,
    } = params;

    const zone = new route53.HostedZone(this, 'HostedZone', {
      zoneName,
    });

    const cert = new acm.Certificate(this, 'Certificate', {
      domainName,
      validation: acm.CertificateValidation.fromDns(zone),
    });

    const vpc = new ec2.Vpc(this, 'VPC', {
      maxAzs: 3,
      natGateways: 0,
    });

    const db = new rds.DatabaseInstance(this, 'RdsInstance', {
      engine: rds.DatabaseInstanceEngine.mysql({ version: rds.MysqlEngineVersion.VER_8_0 }),
      instanceType: ec2.InstanceType.of(ec2.InstanceClass.BURSTABLE4_GRAVITON, ec2.InstanceSize.MICRO),
      credentials: rds.Credentials.fromGeneratedSecret('nabu'),
      databaseName: 'nabu',
      vpc,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PRIVATE_ISOLATED,
      }
    });

    const cluster = new ecs.Cluster(this, 'Cluster', {
      vpc,
    });

    cluster.addCapacity('EcsAsg', {
      minCapacity: 1,
      instanceType: new ec2.InstanceType('t3.medium'),
      associatePublicIpAddress: true,
      vpcSubnets: {
        subnetType: ec2.SubnetType.PUBLIC,
      },
      // machineImage: new ecs.BottleRocketImage(),
    });

    const appTaskDefinition = new ecs.Ec2TaskDefinition(this, 'AppTaskDefinition');
    const appImage = ecs.ContainerImage.fromAsset('..', { file: 'production.Dockerfile' });

    const appArgs = {
      image: appImage,
      memoryLimitMiB: 1024,
      environment: {
        // TODO: do we need nginx in production??
        RAILS_SERVE_STATIC_FILES: 'true',
      },
      secrets: {
        NABU_DATABASE_PASSWORD: ecs.Secret.fromSecretsManager(db.secret as ISecret, 'password'),
        NABU_DATABASE_HOSTNAME: ecs.Secret.fromSecretsManager(db.secret as ISecret, 'host'),
      },
    }

    appTaskDefinition.addContainer('AppContainer', {
      portMappings: [{ containerPort: 3000 }],
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'AppContainer' }),
      ...appArgs,
    });

    const searchTaskDefinition = new ecs.Ec2TaskDefinition(this, 'SearchTaskDefinition');

    searchTaskDefinition.addContainer('SearchContainer', {
      memoryLimitMiB: 1024,
      image: ecs.ContainerImage.fromRegistry('solr:7.7.2'),
      logging: ecs.LogDrivers.awsLogs({ streamPrefix: 'SearchContainer' }),
    });

    const appService = new ecs.Ec2Service(this, 'AppService', {
      cluster,
      taskDefinition: appTaskDefinition
    });
    appService.connections.allowToDefaultPort(db);

    const searchService = new ecs.Ec2Service(this, 'SearchService', {
      cluster,
      taskDefinition: searchTaskDefinition
    });

    const appLb = new elbv2.ApplicationLoadBalancer(this, 'AppLoadBalancer', {
      vpc,
      internetFacing: true,
    });
    appLb.addRedirect();

    const appListener = appLb.addListener('AppListener', {
      port: 443,
      certificates: [cert],
    });

    const app = appListener.addTargets('ECS', {
      port: 80,
      targets: [appService],
    });

    new route53.ARecord(this, 'Alias', {
      recordName: domainName,
      zone,
      target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(appLb)),
    });
    new route53.AaaaRecord(this, 'AliasAAAA', {
      recordName: domainName,
      zone,
      target: route53.RecordTarget.fromAlias(new targets.LoadBalancerTarget(appLb)),
    });

    const dbMigrateDefinition = new ecs.Ec2TaskDefinition(this, 'DbMigrateDefinition');
    dbMigrateDefinition.addContainer('DbMigrateContainer', {
      command: ['bin/rails', 'db:migrate'],
      logging: new ecs.AwsLogDriver({ streamPrefix: 'DbMigrate' }),
      ...appArgs,
    });
  }
}
