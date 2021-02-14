SHELL := /bin/bash
.SHELLFLAGS = -o pipefail -c
TESTDIR  = $(CURDIR)/test/
FIXTUREDIR  = $(TESTDIR)/fixture/
TMPFILE := $(shell mktemp)

export TF_DATA_DIR ?= $(FIXTUREDIR)/.terraform

define terraform_fmt
    terraform fmt -write=false $(1) &> $(TMPFILE)
	if [ -s $(TMPFILE) ]; then echo "Some terraform files need be formatted, run 'terraform fmt' to fix"; rm $(TMPFILE); exit 1; fi && rm $(TMPFILE)
endef

.PHONY: all
## Default target
all: test

.PHONY : validate_all
validate_all: validate validate_examples validate_tests

.PHONY : format_all
format_all: format format_examples format_tests

.PHONY : test
## Run tests
test: validate_all format_all tfsec
	cd $(TESTDIR) && go test -v -timeout 30m

.PHONY : init
init:
	terraform init -input=false -backend=false

.PHONY : format
format:
	$(call terraform_fmt,'.')

.PHONY : validate
validate: init
	AWS_DEFAULT_REGION="us-east-1" terraform validate 

.PHONY : tfsec
tfset: init 
	docker run --rm -it -v "$(pwd):/src" liamg/tfsec /src

.PHONY : init_tests
init_tests:
	pushd test/fixture && terraform init -input=false -backend=false && popd

.PHONY : format_tests
format_tests:
	$(call terraform_fmt,'test/fixture')

.PHONY : validate_tests
validate_tests: init_tests
	pushd test/fixture && terraform validate && popd

.PHONY : init_examples
init_examples:
	pushd examples/simple && terraform init -input=false -backend=false && popd

.PHONY : format_examples
format_examples:
	$(call terraform_fmt,'examples/simple')

.PHONY : validate_examples
validate_examples: init_examples 
	pushd examples/simple && terraform validate && popd

.PHONY : clean
## Clean up files
clean:
	rm -rf $(TF_DATA_DIR) .terraform/
