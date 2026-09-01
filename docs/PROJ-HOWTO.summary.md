# PROJ-HOWTO.summary.md — terraform-utils

Task list only; see [PROJ-HOWTO.md](PROJ-HOWTO.md) for full steps.

- **install the tools** — get `tf-plan-all` and `migrate-tfstate` onto your `PATH` via `make install`.
- **batch-plan every Terraform root module and see what's drifted** — run `terraform plan` across a directory tree and get a pass/fail summary table instead of scrolling per-module output.
- **migrate a module's local state to the shared S3 backend** — move a module off local `terraform.tfstate` onto the shared S3 backend, dry-run first.
- **point either tool at a non-default config file** — run `migrate-tfstate` against an alternate YAML via `--config`; `tf-plan-all` has no config dependency.
- **get AI-powered help mid-command** — both tools wire in k8-lib's `assist.sh` if present; `tf-plan-all` degrades gracefully without it, `migrate-tfstate` requires k8-lib regardless.
