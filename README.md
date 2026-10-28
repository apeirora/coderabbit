# Shared CodeRabbit configuration

Organization-wide CodeRabbit summary defaults for ApeiroRA repositories.
The summary wording is product-neutral and useful to the whole team, not only
developers familiar with the implementation.

## Scope

The root `.coderabbit.yaml` enables high-level summaries and defines four short
sections, with a total limit of 150 words:

1. **What changes:** practical impact on users, operators, or contributors.
2. **Why it matters:** the problem addressed or benefit, with uncertainty stated.
3. **Compatibility:** breaking API, configuration, or behavior changes.
4. **Action needed:** upgrade, migration, deployment, or configuration steps.

It does not configure PII detection, security tools, review profiles, notification
verbosity, automatic review scheduling, approval policies, or merge gates.
Summary placement is left to the existing settings.

## How it applies

CodeRabbit discovers this repository by its required name, `coderabbit`.
The CodeRabbit GitHub App must have access to this repository. Once the config
is merged into `main`, it applies to eligible organization repositories without
their own higher-priority configuration, on subsequent reviews.

`inheritance: true` requests inheritance from existing lower-priority settings
rather than replacing them with schema defaults. Each parent level controls
whether inheritance continues further. Organization and workspace global
overrides still take precedence. Existing effective settings must be compared
before claiming that all inherited behavior is unchanged.

A repository-local configuration takes precedence. Such repositories must use
their own `inheritance: true` to inherit this central baseline. This is a shared
default, not an enforced policy, and it does not install CodeRabbit elsewhere.
It does not automatically rewrite summaries on existing pull requests.

Central configuration documentation:
https://docs.coderabbit.ai/configuration/central-configuration

Inheritance documentation:
https://docs.coderabbit.ai/configuration/configuration-inheritance

## Validate locally

No application build is required. With `uv` installed, validate against the
official CodeRabbit schema without adding dependencies to this repository:

```sh
uvx check-jsonschema \
  --schemafile https://www.coderabbit.ai/integrations/schema.v2.json \
  .coderabbit.yaml
git diff --check
```

Summary customization documentation:
https://docs.coderabbit.ai/pr-reviews/summaries

## Verify the rollout

1. Confirm the CodeRabbit GitHub App has access to this repository.
2. After merging, inspect a subsequent review on a repository without local
   CodeRabbit configuration.
3. Request `@coderabbitai configuration` there when authorized. Confirm the
   central source is `apeirora/coderabbit/.coderabbit.yaml`, the summary
   instructions match, and unrelated settings retain their prior values.
4. Check that the summary uses the four sections, stays concise, and avoids
   fixed product branding and implementation inventories.

Rollback: revert the configuration commit through normal review. Future reviews
then use the previous configuration resolution; existing comments are not undone.
