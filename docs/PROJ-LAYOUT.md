# Project Layout — terraform-utils

Terminal utility package: batch Terraform planning and local→S3 state migration. Scripts source the shared `k8-lib` shell library (`~/.local/share/k8-lib`, overridable via `K8_LIB_DIR`) and install to `~/.local/bin` via `make install`.

```
terraform-utils/
├── bin/                        # Executable CLI tools (installed to ~/.local/bin)
│   ├── tf-plan-all             #   zsh — run `terraform plan` in every subdir with .tf files;
│   │                           #   status table (No Changes | Has Changes | Error | Skipped);
│   │                           #   logs non-clean plans to <dir>/tf-plan-logs/; --verbose timing
│   └── migrate-tfstate         #   bash — add S3 backend config to a module and migrate its
│                               #   local terraform.tfstate; --dry-run / --upload / --config;
│                               #   reads .terraform.* + .aws.* from infra-config.yaml via k8-lib
├── docs/                       # Documentation
│   ├── PROJ-ARCH.md            #   Architecture notes
│   ├── PROJ-ARCH.summary.md    #   Architecture summary companion
│   ├── PROJ-LAYOUT.md          #   This file
│   ├── PROJ-LAYOUT.summary.md  #   Layout summary companion
│   ├── PROJ-SCHEMA.md          #   Config/data artifact reference (no DB layer)
│   ├── PROJ-SCHEMA.summary.md  #   Schema summary companion
│   ├── PROJ-HOWTO.md           #   Task-oriented how-to recipes
│   ├── PROJ-HOWTO.summary.md   #   How-to summary companion
│   ├── PROJ-FAQ.md             #   Frequently asked questions
│   └── PROJ-FAQ.summary.md     #   FAQ summary companion
├── merge-notes.md              # Working notes from the utilities-source consolidation
├── .gitignore                  # Ignores Terraform artifacts (.terraform/, *.tfstate, *.tfplan,
│                               # .terraform.lock.hcl, override.tf*), editor swap files, .env(.local)
├── Makefile                    # `make install` → installs both bin/ tools to $INSTALL_DIR
│                               # (default ~/.local/bin); compile/test are no-ops
└── README.md                   # Start here — install, prerequisites, config table, usage
```

## Key Files Requiring Setup

| File | Action |
|------|--------|
| `infra-config.yaml` (repo root, external) | `migrate-tfstate` reads `.terraform.state_bucket`, `.terraform.kms_alias`, `.terraform.lock_table`, `.aws.profile`, `.aws.region`; env overrides `K8_TF_*` / `K8_AWS_*` |
| k8-lib (`~/.local/share/k8-lib`) | Must be installed (repo `make install-utilities`); both tools source its `config.sh` / `common.sh` / `assist.sh` |

## Notes

- `tf-plan-all` needs no configuration; `migrate-tfstate` requires AWS credentials and the state bucket stack applied first.
- `tf-plan-logs/` directories are runtime output created inside the scanned tree, not part of this package.
