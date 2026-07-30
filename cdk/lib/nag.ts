import * as cdk from 'aws-cdk-lib';
import { AwsSolutionsChecks, type INagValidationContext } from 'cdk-nag';
import type { IConstruct } from 'constructs';

interface NagAcknowledgement {
  id: string;
  reason: string;
}

// cdk-nag v3 matches acknowledgements against the bare rule id (`AwsSolutions-RDS2`,
// `AwsSolutions-IAM5[Resource::*]`) recorded in acknowledged-rules metadata, walking up the
// construct tree. `Validations.of(scope).acknowledge()` cannot produce those ids: it namespaces
// bare ids as `Annotation::<id>` and rejects any id containing more than one `::`, which excludes
// granular findings like `AwsSolutions-IAM4[Policy::arn:<AWS::Partition>:...]`. So write the
// metadata directly.
export const acknowledgeNag = (scope: IConstruct, ...rules: NagAcknowledgement[]) => {
  for (const { id, reason } of rules) {
    scope.node.addMetadata(cdk.Validations.ACKNOWLEDGED_RULES_METADATA_KEY, { [id]: reason });
  }
};

const FINDING_SUFFIX = /\[.*\]$/;

const acknowledgementsByPath = (root: IConstruct) => {
  const byPath = new Map<string, Set<string>>();

  const walk = (scope: IConstruct) => {
    const ids = scope.node.metadata
      .filter((entry) => entry.type === cdk.Validations.ACKNOWLEDGED_RULES_METADATA_KEY && entry.data)
      .flatMap((entry) => Object.keys(entry.data as object));
    if (ids.length > 0) {
      byPath.set(scope.node.path, new Set(ids));
    }
    scope.node.children.forEach(walk);
  };
  walk(root);

  return byPath;
};

// cdk-nag only honours acknowledgements that name a granular finding in full, so acknowledging
// `AwsSolutions-IAM5` does nothing for `AwsSolutions-IAM5[Action::s3:GetObject*]`. The finding
// suffixes embed stack names and logical id hashes, making them impractical to enumerate, so
// restore the v2 behaviour where acknowledging the rule covers all of its findings.
export class NabuSolutionsChecks extends AwsSolutionsChecks {
  validate(context: cdk.IPolicyValidationContext): cdk.PolicyValidationPluginReport {
    const report = super.validate(context);
    const acknowledged = acknowledgementsByPath((context as INagValidationContext).appConstruct);

    const isAcknowledged = (constructPath: string, ruleId: string) => {
      const rule = ruleId.replace(FINDING_SUFFIX, '');
      if (rule === ruleId) return false;

      const scopes = constructPath.split('/');
      return scopes.some((_, index) => acknowledged.get(scopes.slice(0, scopes.length - index).join('/'))?.has(rule));
    };

    const violations = report.violations
      .map((violation) => ({
        ...violation,
        violatingResources: violation.violatingResources.filter((resource) => !isAcknowledged(resource.constructPath ?? '', violation.ruleName)),
      }))
      .filter((violation) => violation.violatingResources.length > 0);

    return { ...report, violations, success: violations.length === 0 };
  }
}
