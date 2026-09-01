# PROJ-FAQ.summary.md — terraform-utils

Question list only; see [PROJ-FAQ.md](PROJ-FAQ.md) for full answers.

## Motivation
- Why would I use `tf-plan-all` instead of just scripting a loop over `terraform plan`?
- Why would I use `migrate-tfstate` instead of hand-writing a `backend.tf` and running `terraform init -migrate-state` myself?

## Fit
- When is `tf-plan-all` the wrong tool for the job?
- When should I reach for `migrate-tfstate` versus leaving a module on local state?
- When should I use `--upload` instead of letting `migrate-tfstate` run interactively?

## Comparison
- How does `tf-plan-all` differ from `terragrunt run --all plan`?
- Why is `tf-plan-all` a zsh script while `migrate-tfstate` is bash?

## Capability
- Does `tf-plan-all` respect module dependency order across the tree it scans?
- Will `migrate-tfstate` overwrite a `backend.tf` I already hand-wrote?

## Caveats
- What happens if I run `tf-plan-all` on a tree where a module has no `.envrc`?
- Does `migrate-tfstate` work if `k8-lib` isn't installed?
- Can I run `--config` on `tf-plan-all` to point it at an alternate `infra-config.yaml`?

## Trust
- Does either tool ever touch remote state or credentials beyond what I already have configured?
- Where do `tf-plan-all` logs end up, and could they contain sensitive plan output?
