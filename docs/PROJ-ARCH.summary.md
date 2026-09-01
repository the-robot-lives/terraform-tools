# terraform-utils — Architecture Summary

Terminal utility package: two Terraform helper scripts installed to `~/.local/bin` via `make install`, both sourcing the shared k8-lib shell library.

- **tf-plan-all** (zsh): batch `terraform plan` across root modules (dirs with provider blocks); `direnv exec` per module; Unicode summary table; keeps logs only for changed/errored plans in `tf-plan-logs/`; `--verbose` timing + slow-plan warnings
- **migrate-tfstate** (bash): generates S3 `backend.tf` from `infra-config.yaml` via k8-lib config chain (`K8_TF_*`/`K8_AWS_*` env overrides) and runs `terraform init -migrate-state`; `--dry-run` / `--upload` / `--config`
- **Makefile**: install-only; `compile`/`test` no-ops per shared utilities convention
- **Ecosystem**: requires k8-lib at `~/.local/share/k8-lib` (`K8_LIB_DIR` override); `--assist` AI help hook; config-first-env-override layering; targets ad-hoc module trees, not the Terragrunt stacks
- **Design**: independent scripts per lifecycle, zsh globbing for discovery, never overwrite existing `backend.tf`, only-interesting-logs retention
