# terraform-utils

**Repo:** https://github.com/the-robot-lives/terraform-tools

Shell helpers for batch Terraform/OpenTofu planning and S3 state migration.

## What

Two installable CLI scripts:

| Command | Purpose |
|---------|---------|
| `tf-plan-all` | Run `terraform plan` (or `terragrunt run --all plan`) in every root module under a directory; prints a status summary table |
| `migrate-tfstate` | Add S3 backend config to a module and migrate its local state to the remote backend |

## Why

The trl-infra terraform/ stacks hold many root modules; checking drift or migrating state module-by-module by hand is slow and error-prone. These tools batch the work and keep per-module plan logs for review. They are coupled to the trl-infra stack ordering (init → infra → infra-services → platform/*); the binary is OpenTofu per that repo's `root.hcl`.

## Getting Started

Prerequisites:

- `terraform` (or `TF_BIN=tofu` for OpenTofu) and/or `terragrunt`
- `yq` (config loading)
- AWS credentials configured (S3 state migration only)

```bash
make install     # installs tf-plan-all and migrate-tfstate to ~/.local/bin
```

```bash
# Batch plan
tf-plan-all                                  # plan from current directory
tf-plan-all terraform/production/imported    # plan a subtree
tf-plan-all --reconfigure kubernetes         # re-init backend cache, then plan
TF_BIN=tofu tf-plan-all terraform/plain-tofu # plain OpenTofu tree

# Migrate local state to S3
migrate-tfstate terraform/production/services/eks
migrate-tfstate --dry-run terraform/production/iam   # preview only
migrate-tfstate --upload terraform/production/iam    # auto-approve migration
```

## How It Works

- **Plain Terraform trees** — `tf-plan-all` walks the tree for root modules and runs `terraform plan` in each. Set `TF_BIN=tofu` to use OpenTofu.
- **Terragrunt trees** — detection of `terragrunt.hcl` / `root.hcl` switches to `terragrunt run --all plan -- -input=false` from the requested directory. If a repo-local `scripts/tg-minio.sh` wrapper exists, planning delegates through it so MinIO-backed state is reachable via the k8s port-forward.
- **`--reconfigure`** — use when cached backend metadata was initialized against a different endpoint (e.g. MinIO at `https://minio.noizu.com` vs `http://127.0.0.1:9000`).
- **Config** — `migrate-tfstate` reads settings from `infra-config.yaml` via the shared k8-lib config chain; every tool accepts `--config <path>` to override. Relevant keys (env overrides in parentheses): `.terraform.state_bucket` (`K8_TF_STATE_BUCKET`), `.terraform.kms_alias` (`K8_TF_KMS_ALIAS`), `.terraform.lock_table` (`K8_TF_LOCK_TABLE`, default `terraform-lock`), `.aws.profile` (`K8_AWS_PROFILE`, default `terraformer`), `.aws.region` (`K8_AWS_REGION`, default `us-east-1`).
- **Plan output** — status per module: `No Changes`, `Has Changes` (drift), or `Error`. Logs for changed/errored modules are saved to `<dir>/tf-plan-logs/`.

## Docs

- `docs/` — architecture and how-to references
- k8-lib config chain: `../k8-lib/README.md`
