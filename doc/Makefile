###############################################################################
# (c) Copyright 2021 CERN for the benefit of the LHCb Collaboration           #
#                                                                             #
# This software is distributed under the terms of the GNU General Public      #
# Licence version 3 (GPL Version 3), copied verbatim in the file "COPYING".   #
#                                                                             #
# In applying this licence, CERN does not waive the privileges and immunities #
# granted to it by virtue of its status as an Intergovernmental Organization  #
# or submit itself to any jurisdiction.                                       #
###############################################################################
# Minimal makefile for Sphinx documentation
#

# You can set these variables from the command line, and also
# from the environment for SPHINXOPTS.
SPHINXPREFIX  = _env.$(BINARY_TAG)
SPHINXOPTS    ?=
SPHINXBUILD   = $(SPHINXPREFIX)/bin/sphinx-build
SOURCEDIR     = .
BUILDDIR      = _build
GIT_COMMIT    = $(shell git rev-parse --short HEAD)

export PYTHONPATH := $(SPHINXPREFIX):$(PYTHONPATH)

# Put it first so that "make" without argument is like "make help".
help: $(SPHINXBUILD)
	$(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# we install certifi (matching the LCG version) so that we can patch
# cacert.pem (== `python -m certifi`)
$(SPHINXBUILD): requirements.txt Makefile
	python -m pip install --disable-pip-version-check --no-warn-conflicts --ignore-installed \
		--target=$(SPHINXPREFIX) -r $< \
		certifi==`python -c 'import certifi; print(certifi.__version__)'`
	@touch $@

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
html pdf: Makefile $(SPHINXBUILD)
	$(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

linkcheck: Makefile $(SPHINXBUILD)
	cat _certificates/*.crt >> `python -m certifi`  # install CERN CA certificates
	$(SPHINXBUILD) -b linkcheck "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

clean: Makefile $(SPHINXBUILD)
	$(SPHINXBUILD) -M clean "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

purge:
	rm -rf $(SPHINXPREFIX) $(BUILDDIR) 

.PHONY: help html pdf clean purge
