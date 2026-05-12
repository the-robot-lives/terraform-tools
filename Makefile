INSTALL_DIR ?= $(HOME)/.local/bin

.PHONY: compile test install

compile:
	@true

test:
	@true

install:
	@mkdir -p $(INSTALL_DIR)
	@for f in tf-plan-all migrate-tfstate; do \
		install -m 755 "$$f" "$(INSTALL_DIR)/$$f"; \
		echo "✓ Installed $$f"; \
	done
