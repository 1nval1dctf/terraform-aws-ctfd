TESTDIR  = $(CURDIR)/test/
FIXTUREDIR  = $(TESTDIR)/fixture/

export TF_DATA_DIR ?= $(FIXTUREDIR)/.terraform

.PHONY: all
## Default target
all: test


.PHONY : test
## Run tests
test:
	cd $(TESTDIR) && go test -v -timeout 30m

.PHONY : clean
## Clean up files
clean:
	rm -rf $(TF_DATA_DIR)