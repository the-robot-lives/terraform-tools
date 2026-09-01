# PROJ-FAQ.md — terraform-utils

Anticipated why/when/compared-to-what questions. For *how* see
[PROJ-HOWTO.md](PROJ-HOWTO.md); for *what/why-designed-this-way* see
[PROJ-ARCH.md](PROJ-ARCH.md).

## Motivation

### Why would I use `tf-plan-all` instead of just scripting a loop over `terraform plan`?

Because it already does the two things a hand-rolled loop usually gets wrong: it only
treats a directory as a root module if it actually contains a `provider` block (so it
doesn't waste time re-planning every child module referenced via `module {}`), and it
only keeps logs for the runs you care about — modules with drift or errors — deleting
clean-plan logs immediately so `tf-plan-logs/` stays a signal, not an archive. It also
runs each plan through `direnv exec`, so per-directory `.envrc` credentials apply
without you writing that plumbing yourself.

→ *See [PROJ-HOWTO.md#how-to-batch-plan-every-terraform-root-module-and-see-whats-drifted](PROJ-HOWTO.md#how-to-batch-plan-every-terraform-root-module-and-see-whats-drifted).*

### Why would I use `migrate-tfstate` instead of hand-writing a `backend.tf` and running `terraform init -migrate-state` myself?

Mainly to avoid re-deriving the S3 key and backend settings by hand every time. It reads
bucket/KMS-alias/lock-table/profile/region from the same `infra-config.yaml` /
`k8-lib` config chain every other Noizu utility uses (with `K8_TF_*`/`K8_AWS_*` env
overrides), derives the S3 key from the module path automatically, and refuses to
clobber an existing `backend.tf`. The actual state move is still plain
`terraform init -migrate-state` under the hood — this tool just removes the manual,
error-prone bookkeeping around it.

→ *See [PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend](PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend).*

## Fit

### When is `tf-plan-all` the wrong tool for the job?

When you're operating inside a Terragrunt-orchestrated stack (like
`terraform/kubernetes/` in this monorepo) — use `terragrunt run --all plan` there
instead, since it understands Terragrunt's `dependencies` blocks and remote-state
wiring. `tf-plan-all` targets ad-hoc or imported plain-Terraform module trees where
there's no Terragrunt layer to lean on; pointed at a Terragrunt tree it will still find
directories with `provider` blocks and plan them individually, but it has no concept of
inter-stack dependency ordering.

→ *See [PROJ-ARCH.md#ecosystem-fit](PROJ-ARCH.md#ecosystem-fit).*

### When should I reach for `migrate-tfstate` versus leaving a module on local state?

Reach for it once a module needs to be planned/applied from more than one machine or by
more than one person — local `terraform.tfstate` has no locking or shared visibility
across those. For a genuinely single-operator, throwaway, or experimental module, local
state is simpler and migration is unnecessary overhead.

### When should I use `--upload` instead of letting `migrate-tfstate` run interactively?

Use the plain (no-flag) invocation whenever a human is at the keyboard — it hands off to
`terraform init -migrate-state`'s own interactive confirmation, which is your last look
at exactly what's about to move before it moves. Reach for `--upload` only in
non-interactive contexts (CI, a scripted batch migration over many modules) where
nothing would be there to answer the prompt anyway; it skips that same confirmation, so
run `--dry-run` first in those cases since `--upload` won't stop to let you catch a
mistake.

→ *See [PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend](PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend).*

## Comparison

### How does `tf-plan-all` differ from `terragrunt run --all plan`?

`tf-plan-all` is a dumber, dependency-unaware sibling: it discovers root modules by
directory heuristic (a `provider` block) and plans each independently via `direnv exec`,
with no knowledge of module ordering or shared remote state — because it's meant for
trees that never got a Terragrunt layer in the first place. `terragrunt run --all plan`
(used for `terraform/kubernetes/`) understands `dependencies {}` blocks and plans stacks
in the correct order against a shared S3 backend. Don't expect `tf-plan-all` to respect
inter-module dependencies; it doesn't know they exist.

### Why is `tf-plan-all` a zsh script while `migrate-tfstate` is bash?

`tf-plan-all` leans on zsh's extended glob qualifiers (`**/*(/N)`) to make recursive
root-module discovery a one-liner; `migrate-tfstate` needs no such feature, so it stays
in portable bash rather than requiring zsh be installed for a script that doesn't
benefit from it.

→ *See [PROJ-ARCH.md#key-decisions](PROJ-ARCH.md#key-decisions).*

## Capability

### Does `tf-plan-all` respect module dependency order across the tree it scans?

No — each discovered root module is planned independently with no ordering guarantee
between them. If your modules have a hard apply-order dependency, batch-planning them
here won't catch order-sensitive drift the way a Terragrunt `dependencies` graph would.

### Will `migrate-tfstate` overwrite a `backend.tf` I already hand-wrote?

No, by design. If `backend.tf` already exists in the target module, the tool warns and
skips file creation entirely — but it still runs `terraform init -migrate-state`
against whatever backend config is already there, so double-check that file's contents
match what you expect before running it on a hand-edited module.

→ *See [PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend](PROJ-HOWTO.md#how-to-migrate-a-modules-local-state-to-the-shared-s3-backend).*

## Caveats

### What happens if I run `tf-plan-all` on a tree where a module has no `.envrc`?

Whatever `direnv exec` does without one applies — it runs the command with whatever
ambient environment is already active, no per-module credentials injected. If that
module needs AWS/other creds it doesn't already have ambiently, its plan will fail and
get logged under `tf-plan-logs/` as an Error, not silently skipped.

### Does `migrate-tfstate` work if `k8-lib` isn't installed?

No — unlike `tf-plan-all`, which degrades gracefully and simply skips the `--assist`
hook if `k8-lib` is missing, `migrate-tfstate` sources the full k8-lib chain
(`config.sh`/`common.sh`/`assist.sh`) unconditionally at startup and will hard-fail
without it, regardless of whether you wanted AI-assist help at all.

→ *See [PROJ-HOWTO.md#how-to-get-ai-powered-help-mid-command](PROJ-HOWTO.md#how-to-get-ai-powered-help-mid-command).*

### Can I run `--config` on `tf-plan-all` to point it at an alternate `infra-config.yaml`?

No — `--config` is `migrate-tfstate`-only. `tf-plan-all` never sources k8-lib's config
chain at all (it has no bucket/profile/etc. to resolve), so passing `--config` to it is
silently treated as a bogus positional directory argument, not a rejected flag.

→ *See [PROJ-HOWTO.md#how-to-point-either-tool-at-a-non-default-config-file](PROJ-HOWTO.md#how-to-point-either-tool-at-a-non-default-config-file).*

## Trust

### Does either tool ever touch remote state or credentials beyond what I already have configured?

No — both are thin wrappers around the Terraform CLI and your existing credential
chain (`direnv`-sourced env for `tf-plan-all`, the `k8-lib`/`infra-config.yaml`
config chain plus AWS profile for `migrate-tfstate`). Neither tool stores, transmits, or
caches secrets of its own; `migrate-tfstate`'s only generated artifact is the
`backend.tf` file it writes into the target module.

### Where do `tf-plan-all` logs end up, and could they contain sensitive plan output?

Under `<scanned-dir>/tf-plan-logs/<timestamp>-<module>.log`, kept only for modules with
changes or errors (clean-plan logs are deleted immediately). Since these are raw
`terraform plan` outputs, treat them like any other plan output that might reference
resource attribute values — don't commit `tf-plan-logs/` to source control.
