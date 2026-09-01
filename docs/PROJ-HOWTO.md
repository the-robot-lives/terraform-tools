# PROJ-HOWTO.md — terraform-utils

Task-oriented guides for the two CLI tools in this package. For *what it is* see
[PROJ-ARCH.md](PROJ-ARCH.md); for *where things live* see [PROJ-LAYOUT.md](PROJ-LAYOUT.md).

## How to: install the tools

**Goal:** get `tf-plan-all` and `migrate-tfstate` onto your `PATH`.
**Prereqs:** `terraform` CLI, `yq`; for state migration also AWS credentials + a working
`k8-lib` at `~/.local/share/k8-lib` (`K8_LIB_DIR` to override).

1. From this directory:
   ```bash
   make install
   ```
2. This installs both scripts to `~/.local/bin` (override with `make install INSTALL_DIR=<dir>`).

**Verify:**
```bash
which tf-plan-all migrate-tfstate
```
**Gotchas:**
- `~/.local/bin` must be on `PATH` or the tools won't resolve after install.
- `migrate-tfstate` refuses to run at all if `K8_TF_STATE_BUCKET` isn't set anywhere in
  the config chain — see the next guide before running it for the first time.

## How to: batch-plan every Terraform root module and see what's drifted

**Goal:** run `terraform plan` across an entire directory tree and get a pass/fail table
instead of scrolling through dozens of individual `plan` outputs.
**Prereqs:** `tf-plan-all` installed; `direnv` configured for each module (it runs plans
via `direnv exec <dir> terraform ...`, so per-module env/credentials load through direnv).

1. From the tree root you want scanned:
   ```bash
   tf-plan-all
   ```
   or point at a subtree:
   ```bash
   tf-plan-all terraform/production/imported
   ```
2. Add `--verbose`/`-v` to see each module as it's planned, per-plan timing, and a
   warning if any single plan exceeds 5 minutes:
   ```bash
   tf-plan-all --verbose terraform/production/imported
   ```

**Verify:** the run ends with a Unicode summary table (`No Changes` / `Has Changes` /
`Error` counts). Exit code is non-zero iff any module errored.

**Gotchas:**
- Only directories containing a `provider` block are treated as root modules — child
  modules referenced via `module {}` blocks are silently skipped, by design.
- Logs are kept **only** for modules with changes or errors, under
  `<dir>/tf-plan-logs/<timestamp>-<module>.log`; clean-plan logs are deleted immediately.
  Don't expect a log for a "No Changes" module.
- A long-running plan isn't a bug — check the `SLOW PLANS (>5 min)` section at the end
  before assuming something hung.
- Retained logs under `tf-plan-logs/` are raw `terraform plan` output and can contain
  resource attribute values — this package's own `.gitignore` does **not** exclude that
  directory, so add `tf-plan-logs/` to the `.gitignore` of whatever tree you're scanning
  before running this against a repo you don't want plan output committed into.

## How to: migrate a module's local state to the shared S3 backend

**Goal:** move a module off local `terraform.tfstate` onto the shared S3 backend
(bucket/KMS/lock-table sourced from `infra-config.yaml` via k8-lib).
**Prereqs:** `terraform/production/state` (or your bucket/table stack) already applied;
the target module must currently have a **local** `terraform.tfstate` file; AWS
credentials for the configured profile (default `terraformer`).

1. Preview what would happen, no changes made:
   ```bash
   migrate-tfstate --dry-run terraform/production/iam
   ```
2. Run for real (prompts for interactive confirmation from `terraform init -migrate-state`):
   ```bash
   migrate-tfstate terraform/production/iam
   ```
3. Or skip the interactive prompt entirely:
   ```bash
   migrate-tfstate --upload terraform/production/iam
   ```

**Verify:** the module gets a new `backend.tf` and the tool prints
`Done. State for <module> is now in s3://<bucket>/<key>`. Confirm with:
```bash
terraform -chdir=terraform/production/iam state list
```

**Gotchas:**
- Fails fast with "No local terraform.tfstate in `<dir>`" if the module has already been
  migrated or never applied — nothing to migrate from.
- If `backend.tf` already exists in the module, the tool **will not overwrite it** — it
  warns and skips file creation, but still runs `init -migrate-state` against whatever
  backend config is already there. Check that file first if the module was hand-edited.
- If you get `K8_TF_STATE_BUCKET is not set`, the config chain never resolved a bucket —
  set `terraform.state_bucket` in `infra-config.yaml`, or export `K8_TF_STATE_BUCKET`
  directly, or point at a different config file (see next guide).

## How to: point either tool at a non-default config file

**Goal:** run `migrate-tfstate` against settings from a config file other than the
discovered `infra-config.yaml` (e.g. a per-environment override).
**Prereqs:** the alternate YAML follows the same `k8-lib` config-chain shape as
`infra-config.yaml` (see [k8-lib README](../../../../share/k8-lib/README.md)).

1. Pass `--config` with either syntax:
   ```bash
   migrate-tfstate --config=./staging-infra-config.yaml terraform/staging/iam
   migrate-tfstate --config ./staging-infra-config.yaml terraform/staging/iam
   ```

**Verify:** values printed/used (bucket, region, profile) reflect the alternate file —
diff against `infra-config.yaml` if unsure which one won.

**Gotchas:**
- This flag is `migrate-tfstate`-only. `tf-plan-all` has no config dependency at all —
  it never sources k8-lib and takes no `--config` flag (its only flags are
  `--verbose`/`-v`); passing `--config` to it will be treated as a bogus positional
  directory argument, not an error.

## How to: get AI-powered help mid-command

**Goal:** get contextual assistance without leaving the terminal.
**Prereqs:** `k8-lib`'s `assist.sh` present at `$K8_LIB_DIR/bin/assist.sh` (both tools
source it automatically if found).

1. Trigger it per either tool's own `--assist`-style invocation (see `k8-lib`'s assist
   docs for the exact trigger syntax it wires in) — both `tf-plan-all` and
   `migrate-tfstate` call `_k8_check_assist "$0" "$@"` before doing anything else.

**Verify:** if `k8-lib` isn't installed at `$K8_LIB_DIR`, this is silently skipped for
`tf-plan-all` (guarded by a file-exists check) — `migrate-tfstate` sources k8-lib
unconditionally, so it will hard-fail without it.

**Gotchas:**
- `tf-plan-all` degrades gracefully without k8-lib; `migrate-tfstate` does not — it
  requires k8-lib for its config chain regardless of whether you want assist help.
