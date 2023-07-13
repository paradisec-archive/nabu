import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as ec2 from 'aws-cdk-lib/aws-ec2';
import * as elbv2 from 'aws-cdk-lib/aws-elasticloadbalancingv2';
import * as ssm from 'aws-cdk-lib/aws-ssm';

import type { Environment } from './types';

export class NlbStack extends cdk.Stack {
  constructor(scope: Construct, id: string, environment: Environment, props?: cdk.StackProps) {
    super(scope, id, props);

    const { account, region } = environment;

    // ////////////////////////
    // Network
    // ////////////////////////

    const vpc = ec2.Vpc.fromLookup(this, 'VPC', { vpcName: `${account}-${region}-vpc` });

    const publicSubnetIds = ['a', 'b', 'c'].map((az) => ssm.StringParameter.valueForStringParameter(this, `/usyd/resources/subnets/public/apse2${az}-id`));
    const publicSubnets = publicSubnetIds.map((subnetId, index) => ec2.Subnet.fromSubnetAttributes(this, `AppSubnet${index}`, { subnetId }));

    // ////////////////////////
    // Network Load Balancer
    // ////////////////////////

    const nlb = new elbv2.NetworkLoadBalancer(this, 'UsydNLB', {
      vpc,
      vpcSubnets: {
        subnets: publicSubnets,
      },
      internetFacing: false,
    });

    new ssm.StringParameter(this, 'NLBArnParameter', {
      parameterName: '/nabu/resources/nlbs/usyd',
      stringValue: nlb.loadBalancerArn,
    });
  }
}
