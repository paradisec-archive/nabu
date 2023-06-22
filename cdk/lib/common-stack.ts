import * as cdk from 'aws-cdk-lib';
import { Construct } from 'constructs';

import * as route53 from 'aws-cdk-lib/aws-route53';

export class CommonStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    const zone = new route53.HostedZone(this, 'HostedZone', {
      zoneName: 'catalog.paradisec.org.au',
    });

    new route53.ARecord(this, 'CatalogARecord', {
      zone,
      target: route53.RecordTarget.fromIpAddresses('203.101.227.233'),
    });
  }
}
