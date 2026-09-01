# Project Layout Summary — terraform-utils

```
terraform-utils/
├── bin/                        # CLI tools → ~/.local/bin
│   ├── tf-plan-all             #   batch terraform plan + status table
│   └── migrate-tfstate         #   local tfstate → S3 backend migration
├── docs/                       # PROJ-ARCH / -LAYOUT / -SCHEMA / -HOWTO / -FAQ (.summary.md each)
├── merge-notes.md              # Consolidation working notes
├── CLAUDE.md                   # Claude Code guidance
├── .gitignore                  # Terraform artifacts, editor swap, .env
├── Makefile                    # make install
└── README.md                   # Install, config, usage
```
