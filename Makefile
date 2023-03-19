SHELL := /bin/bash
.SHELLFLAGS = -o pipefail -c
TESTDIR  = $(CURDIR)/test/
FIXTUREDIR  = $(TESTDIR)/fixture/
TMPFILE := $(shell mktemp)
MODULES := $(wildcard modules/*/.)
EXAMPLES := $(wildcard examples/*/.)
TEST_FIXTURES := $(wildcard test/*/.)


.PHONY: all
## Default target
all: test pre-commit

.PHONY : init_all
init_all: init init_examples init_tests init_modules

.PHONY : test
## Run tests
test: init_tests
	pushd $(TESTDIR) && go test -v -timeout 10m -run TestDocker && popd

.PHONY : test_aws
## Run tests
test_aws: init_tests
	pushd $(TESTDIR) && go test -v -timeout 40m -run TestAws && popd

.PHONY : init
init:
	terraform init -upgrade -input=false -backend=false

.PHONY : init_tests
init_tests:
	for TEST in $(TEST_FIXTURES); do \
		echo "terraform init $$TEST"; \
		pushd $$TEST && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : init_examples
init_examples:
	for EXAMPLE in $(EXAMPLES); do \
		echo "terraform init $$EXAMPLE"; \
		pushd $$EXAMPLE && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : init_modules
init_modules:
	for MODULE in $(MODULES); do \
		echo "terraform init $$MODULE"; \
		pushd $$MODULE && terraform init -upgrade -input=false -backend=false && popd; \
	done

.PHONY : pre-commit
pre-commit: pre-commit-check clean init_all terrascan-init tflint-init
	pre-commit run -a

.PHONY : pre-commit-check
pre-commit-check:
	$(if $(shell command -v pre-commit 2> /dev/null),,$(error pre-commit is required but not found, please follow https://github.com/antonbabenko/pre-commit-terraform#how-to-install)`)

tflint-init:
	tflint --init

terrascan-init:
	terrascan init

.PHONY : clean
## Clean up files
clean:
	$(if $(shell find . -type d -name ".terraform" -print0),find . -type d -name ".terraform" -print0 | xargs -0 rm -r,)
