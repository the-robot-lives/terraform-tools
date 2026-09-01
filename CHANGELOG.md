# Changelog — utilities/terraform/terraform-utils

## [Unreleased]
- No changes since the last milestone.

## [m2-npl-docs] — 2026-07-16 — tag: `utilities-terraform-terraform-utils/m2-npl-docs`
Milestone summary: reworked PROJ-ARCH into the standard NPL per-level architecture format and added a PROJ-LAYOUT doc, bringing this utility's docs in line with the monorepo-wide NPL doc conventions.

### Added
- `docs/PROJ-LAYOUT.md` + `docs/PROJ-LAYOUT.summary.md`
### Changed
- `docs/PROJ-ARCH.md` restructured/expanded; `docs/PROJ-ARCH.summary.md` tightened

## [m1-initial-tooling] — 2026-06-14 — tag: `utilities-terraform-terraform-utils/m1-initial-tooling`
Milestone summary: introduced the terraform-tools package — `tf-plan-all` (batch `terraform plan` across root modules with a pass/fail summary table) and `migrate-tfstate` (add S3 backend config to a module and migrate its local state, config-driven via the shared k8-lib config chain) — installable to `~/.local/bin` via `make install`.

### Added
- `bin/tf-plan-all` — batch-plans every root module under a directory tree; logs modules with changes/errors to `tf-plan-logs/`
- `bin/migrate-tfstate` — migrates a module's local Terraform state to the shared S3 backend (bucket/KMS/lock-table/AWS profile sourced from `infra-config.yaml` or env overrides), with `--dry-run` and `--upload` modes
- `Makefile` (`install` target → `~/.local/bin`), `README.md`, `docs/PROJ-ARCH.md`, `docs/PROJ-ARCH.summary.md`
- `.gitignore`

## Notes
- This directory is a git subtree (`utilities/terraform/terraform-utils`); prior to m1 its content was squash-merged in via two subtree-add commits (2026-06-08 and a duplicate re-add on 2026-06-13, identical content) — not separately milestoned since neither introduced changes of its own.
