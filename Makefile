SHELL := /bin/bash
.SHELLFLAGS = -o pipefail -c
TESTDIR  = $(CURDIR)/test/
FIXTUREDIR  = $(TESTDIR)/fixture/
TMPFILE := $(shell mktemp)
MODULES := $(wildcard modules/*/.)

export TF_DATA_DIR ?= $(FIXTUREDIR)/.terraform

define terraform_fmt
    terraform fmt -write=false $(1) &> $(TMPFILE)
	if [ -s $(TMPFILE) ]; then echo "Some terraform files need be formatted, run 'terraform fmt' to fix"; rm $(TMPFILE); exit 1; fi && rm $(TMPFILE)
endef

.PHONY: all
## Default target
all: test

.PHONY : validate_all
validate_all: validate validate_examples validate_tests validate_modules

.PHONY : format_all
format_all: format format_examples format_tests format_modules

.PHONY : test
## Run tests
test: validate_all format_all tfsec
	cd $(TESTDIR) && go test -v -timeout 30m -run TestK3s

.PHONY : init
init:
	terraform init -upgrade -input=false -backend=false

.PHONY : format
format:
	$(call terraform_fmt,'.')

.PHONY : validate
validate: init
	AWS_DEFAULT_REGION="us-east-1" terraform validate 

.PHONY : tfsec
tfsec: init 
	docker run --rm -it -v `pwd`:/src tfsec/tfsec --exclude AWS007,AWS066,AWS068,AWS069,AWS082 /src

.PHONY : tflint
tflint: init 
	docker run --rm -t -v `pwd`:/data wata727/tflint

.PHONY : init_tests
init_tests:
	pushd test/fixture && terraform init -upgrade -input=false -backend=false && popd

.PHONY : format_tests
format_tests:
	$(call terraform_fmt,'test/fixture')
	$(call terraform_fmt,'test/k3s_fixture')

.PHONY : validate_tests
validate_tests: init_tests
	pushd test/fixture && terraform validate && popd

.PHONY : init_examples
init_examples:
	pushd examples/simple && terraform init -upgrade -input=false -backend=false && popd

.PHONY : format_examples
format_examples:
	$(call terraform_fmt,'examples/simple')
	$(call terraform_fmt,'examples/existing_k8s')

.PHONY : validate_examples
validate_examples: init_examples 
	pushd examples/simple && terraform validate && popd

.PHONY : init_modules
init_modules:
	for MODULE in $(MODULES); do \
		echo "terraform init $$MODULE"; \
		pushd $$MODULE && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : format_modules
format_modules:
	for MODULE in $(MODULES); do \
		echo "terraform fmt $$MODULE"; \
	    terraform fmt -write=false $$MODULE &> $(TMPFILE); \
		if [ -s $(TMPFILE) ]; then echo "Some terraform files need be formatted, run 'terraform fmt' to fix"; rm $(TMPFILE); exit 1; fi && rm $(TMPFILE); \
	done

.PHONY : validate_modules
validate_modules: init_modules 
	for MODULE in $(MODULES); do \
		echo "terraform validate $$MODULE"; \
		pushd $$MODULE && AWS_DEFAULT_REGION="us-east-1" terraform validate && popd; \
	done

.PHONY : clean
## Clean up files
clean:
	rm -rf $(TF_DATA_DIR) .terraform/
