# Makefile for Sphinx documentation

# use bash for pushd/popd, and to fail quickly
SHELL = bash -e -o pipefail

# You can set these variables from the command line.
SPHINXOPTS   ?=
SPHINXBUILD  ?= sphinx-build
SOURCEDIR    ?= .
BUILDDIR     ?= _build

# name of python virtualenv that is used to run commands
VIRTUALENV   := python3 -m venv
VENV_NAME    := venv_docs

# Other repos with documentation to include.
# edit the `git_refs` file with the commit/tag/branch that you want to use
OTHER_REPO_DOCS ?=  sdran-in-a-box onos-operator onos-e2t onos-e2-sm onos-e2sub onos-api onos-ric-sdk-go onos-kpimon onos-pci onos-config onos-topo onos-cli ran-simulator

.PHONY: help test lint doc8 reload Makefile prep

# Put it first so that "make" without argument is like "make help".
help: $(VENV_NAME)
	source $</bin/activate ; set -u ;\
  $(SPHINXBUILD) -M help "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)

# Create the virtualenv with all the tools installed
$(VENV_NAME):
	$(VIRTUALENV) $@ ;\
  source $@/bin/activate ;\
  pip install -r requirements.txt

# automatically reload changes in browser as they're made
reload: $(VENV_NAME)
	source $</bin/activate ; set -u ;\
  sphinx-reload $(SOURCEDIR)

# lint and link verification. linkcheck is part of sphinx
test: lint linkcheck spelling

lint: doc8

doc8: $(VENV_NAME) | $(OTHER_REPO_DOCS)
	source $</bin/activate ; set -u ;\
  doc8 --max-line-length 119 \
  $$(find . -name \*.rst ! -path "*venv*" ! -path "*vendor*" ! -path "*repos*" )

license: $(VENV_NAME)
	source $</bin/activate ; set -u ;\
  reuse --version ;\
  reuse --root . lint

# clean up
clean:
	rm -rf $(BUILDDIR) $(OTHER_REPO_DOCS)

clean-all: clean
	rm -rf $(VENV_NAME) repos

# checkout the repos inside repos/ dir
repos:
	mkdir repos

# build directory paths in repos/* to perform 'git clone <repo>' into
CHECKOUT_REPOS   = $(foreach repo,$(OTHER_REPO_DOCS),repos/$(repo))

# Host holding the git server
REPO_HOST       ?= git@github.com:onosproject

# For QA patchset validation - set SKIP_CHECKOUT to the repo name and
# pre-populate it under repos/ with the specific commit to being validated
SKIP_CHECKOUT   ?=

# clone (only if doesn't exist)
$(CHECKOUT_REPOS): | repos
	if [ ! -d '$@' ] ;\
    then git clone $(REPO_HOST)/$(@F) $@ ;\
  fi

# checkout correct ref if not under test, then copy subdirectories into main
# docs dir
$(OTHER_REPO_DOCS): | $(CHECKOUT_REPOS)
	if [ "$(SKIP_CHECKOUT)" != "$@" ] ;\
    then GIT_REF=`grep '^$@ ' git_refs | awk '{print $$3}'` ;\
    cd "repos/$@" && git fetch && git checkout $$GIT_REF ;\
  fi
	GIT_SUBDIR=`grep '^$@ ' git_refs | awk '{print $$2}'` ;\
  cp -r repos/$(@)$$GIT_SUBDIR $@ ;\

# generate a list of git checksums suitable for updating git_refs
freeze: repos
	@for repo in $(OTHER_REPO_DOCS) ; do \
  GIT_SUBDIR=`grep "^$$repo " git_refs | awk '{print $$2}'` ;\
    cd "repos/$$repo" > /dev/null ;\
    HEAD_SHA=`git rev-parse HEAD` ;\
    printf "%-24s %-8s %-40s\n" $$repo $$GIT_SUBDIR $$HEAD_SHA ;\
  cd ../.. ;\
  done

# prep target - used in sphinx-multiversion to check out repos
prep: | $(OTHER_REPO_DOCS)

# build multiple versions
multiversion: $(VENV_NAME) Makefile | prep $(OTHER_REPO_DOCS)
	source $</bin/activate ; set -u ;\
  sphinx-multiversion "$(SOURCEDIR)" "$(BUILDDIR)/multiversion" $(SPHINXOPTS)
	cp "$(SOURCEDIR)/_templates/meta_refresh.html" "$(BUILDDIR)/multiversion/index.html"

# Catch-all target: route all unknown targets to Sphinx using the new
# "make mode" option.  $(O) is meant as a shortcut for $(SPHINXOPTS).
%: $(VENV_NAME) Makefile | $(OTHER_REPO_DOCS)
	source $</bin/activate ; set -u ;\
  $(SPHINXBUILD) -M $@ "$(SOURCEDIR)" "$(BUILDDIR)" $(SPHINXOPTS) $(O)
