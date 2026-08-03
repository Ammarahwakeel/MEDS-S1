# Copyright 2026 Maktab-e-Digital Systems Lahore.
# SPDX-License-Identifier: Apache-2.0
#
# MEDS-S1 documentation build.
#
#   make docs      figures + specification PDF          (the usual target)
#   make figures   regenerate docs/figures/*.svg only
#   make pdf       rebuild the PDF from existing figures
#   make html      also keep the intermediate HTML
#   make clean     remove generated artefacts
#
# Requires: python3, pandoc, google-chrome or chromium.
# Optional: mmdc (@mermaid-js/mermaid-cli) -- without it, mermaid diagrams are
# omitted from the PDF and everything else still builds.

PY      := python3
SCRIPTS := scripts
DOCS    := docs
FIGS    := $(DOCS)/figures
PDF     := $(DOCS)/MEDS-S1-Specification.pdf
SPEC    := specs/MEDS-S1-SPECIFICATION.md

# mmdc drives puppeteer, which otherwise hunts for a Chrome it did not install.
export PUPPETEER_EXECUTABLE_PATH ?= $(shell command -v google-chrome || command -v chromium || command -v chromium-browser)

.PHONY: docs figures pdf html clean check-tools

docs: figures pdf

figures:
	@$(PY) $(SCRIPTS)/gen_diagrams.py

pdf: $(PDF)

$(PDF): $(SPEC) $(SCRIPTS)/build_pdf.py $(wildcard $(FIGS)/*.svg)
	@$(PY) $(SCRIPTS)/build_pdf.py

html:
	@$(PY) $(SCRIPTS)/build_pdf.py --gen --keep-html

check-tools:
	@for t in pandoc $(PY); do \
	  command -v $$t >/dev/null || { echo "missing: $$t"; exit 1; }; done
	@command -v google-chrome >/dev/null || command -v chromium >/dev/null || \
	  { echo "missing: google-chrome or chromium"; exit 1; }
	@command -v mmdc >/dev/null || echo "note: mmdc not found -- mermaid diagrams will be omitted"
	@echo "toolchain ok"

clean:
	@rm -f $(PDF) $(DOCS)/MEDS-S1-Specification.html
	@rm -rf $(FIGS)
	@echo "cleaned"
