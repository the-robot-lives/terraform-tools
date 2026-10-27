# AGENT-README

> Orientation for AI coding agents working in this repo. Human docs: README.md.

## Type

scripts+cli-tool

## Purpose

Shell helpers for batch Terraform/OpenTofu work — `tf-plan-all` (plan every root module under a directory with a status summary table) and `migrate-tfstate` (add S3 backend config and migrate local state to the remote backend).

## Stack

Bash CLIs installed to `~/.local/bin`; `yq` for config loading; shared k8-lib config chain over `infra-config.yaml`; coupled to the trl-infra stack ordering (init → infra → infra-services → platform/*).

## Dev mode

```bash
make install     # installs tf-plan-all and migrate-tfstate to ~/.local/bin
tf-plan-all      # plan from current directory (or a subtree argument)
migrate-tfstate --dry-run <module>   # preview state migration
```

## Ports / URLs

- none (library/CLI)

## Tests

```bash
make test
```

## Gotchas

- `TF_BIN=tofu` for OpenTofu (trl-infra's binary per `root.hcl`); terragrunt trees (`terragrunt.hcl` / `root.hcl`) auto-switch to `terragrunt run --all plan`.
- MinIO-backed state needs the k8s port-forward — if a repo-local `scripts/tg-minio.sh` exists, planning delegates through it; use `--reconfigure` when cached backend metadata points at a different endpoint (e.g. MinIO URL changed).
- Config via `infra-config.yaml` with env overrides: `.terraform.state_bucket` (`K8_TF_STATE_BUCKET`), `.terraform.lock_table` (`K8_TF_LOCK_TABLE`, default `terraform-lock`), `.aws.profile` (`K8_AWS_PROFILE`, default `terraformer`), `.aws.region` (`K8_AWS_REGION`, default `us-east-1`).
