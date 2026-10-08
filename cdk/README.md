# Nabu infrastructure

AWS CDK app for Nabu's staging and production stacks. `cdk.json` typechecks with `tsc` and then runs `bin/app.ts` with `tsx`.

## Useful commands

* `pnpm build`        typecheck
* `pnpm cdk diff`     compare deployed stack with current state
* `pnpm cdk synth`    emit the synthesised CloudFormation templates
* `pnpm cdk deploy`   deploy a stack
