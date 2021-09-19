SHELL := /bin/bash
.SHELLFLAGS = -o pipefail -c
TESTDIR  = $(CURDIR)/test/
FIXTUREDIR  = $(TESTDIR)/fixture/
TMPFILE := $(shell mktemp)
MODULES := $(wildcard modules/*/.)
EXAMPLES := $(wildcard examples/*/.)
TEST_FIXTURES := $(wildcard test/*/.)

export TF_DATA_DIR ?= $(FIXTUREDIR)/.terraform


.PHONY: all
## Default target
all: test

.PHONY : validate_all
validate_all: validate validate_examples validate_tests validate_modules

.PHONY : format_all
format_all: format format_examples format_tests format_modules

.PHONY : test
## Run tests
test: validate_all tfsec
	cd $(TESTDIR) && go test -v -timeout 10m -run TestK3s

.PHONY : test_aws
## Run tests
test_aws: validate_all tfsec
	cd $(TESTDIR) && go test -v -timeout 40m -run TestAws

.PHONY : init
init:
	terraform init -upgrade -input=false -backend=false

.PHONY : format
format:
	terraform fmt .

.PHONY : validate
validate: init
	AWS_DEFAULT_REGION="us-east-1" terraform validate || exit;
	terraform fmt --check || exit;

.PHONY : tfsec
tfsec: init 
	docker run --rm -it -v `pwd`:/src tfsec/tfsec --exclude AWS007,AWS066,AWS068,AWS069,AWS082 /src

.PHONY : tflint
tflint: init 
	docker run --rm -t -v `pwd`:/data wata727/tflint

.PHONY : init_tests
init_tests:
	for TEST in $(TEST_FIXTURES); do \
		echo "terraform init $$TEST"; \
		pushd $$TEST && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : format_tests
format_tests:
	for TEST in $(TEST_FIXTURES); do \
		echo "terraform fmt $$TEST"; \
	    terraform fmt $$TEST || exit; \
	done

.PHONY : validate_tests
validate_tests: init_tests
	for TEST in $(TEST_FIXTURES); do \
		pushd $$TEST; \
		echo "terraform validate $$TEST"; \
		terraform validate || exit; \
		echo "terraform fmt $$TEST"; \
		terraform fmt --check || exit; \
		popd; \
	done

.PHONY : init_examples
init_examples:
	for EXAMPLE in $(EXAMPLES); do \
		echo "terraform init $$EXAMPLE"; \
		pushd $$EXAMPLE && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : format_examples
format_examples:
	for EXAMPLE in $(EXAMPLES); do \
		echo "terraform fmt $$EXAMPLE"; \
	    terraform fmt $$EXAMPLE || exit; \
	done

.PHONY : validate_examples
validate_examples: init_examples
	for EXAMPLE in $(EXAMPLES); do \
		pushd $$EXAMPLE; \
		echo "terraform validate $$EXAMPLE"; \
		terraform validate || exit; \
		echo "terraform fmt $$EXAMPLE"; \
		terraform fmt --check || exit; \
		popd; \
	done

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
	    terraform fmt $$MODULE || exit; \
	done

.PHONY : validate_modules
validate_modules: init_modules 
	for MODULE in $(MODULES); do \
		pushd $$MODULE; \
		echo "terraform validate $$MODULE"; \
		AWS_DEFAULT_REGION="us-east-1" terraform validate  || exit; \
		echo "terraform fmt $$MODULE"; \
		terraform fmt --check || exit; \
		popd; \
	done

.PHONY : clean
## Clean up files
clean:
	rm -rf $(TF_DATA_DIR) .terraform/
