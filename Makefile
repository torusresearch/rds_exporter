# Copyright 2017 The Prometheus Authors
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

GO    := go
PROMU := $(GOPATH)/bin/promu
pkgs   = $(shell $(GO) list ./...)

PREFIX                  ?= $(shell pwd)
BIN_DIR                 ?= $(shell pwd)
DOCKER_IMAGE_NAME       ?= $(shell basename $(shell pwd))
DOCKER_IMAGE_TAG        ?= $(subst /,-,$(shell git rev-parse --abbrev-ref HEAD))


all: format build test

style:
	@echo ">> checking code style"
	@! gofmt -d $(shell find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'

test:
	@echo ">> running tests"
	@$(GO) test $(pkgs)

test-race:
	@echo ">> running tests"
	@$(GO) test -v -race $(pkgs)

format:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)

vet:
	@echo ">> vetting code"
	@$(GO) vet $(pkgs)

build:
	@echo ">> building binaries"
	@$(PROMU) build --prefix $(PREFIX)

tarball: promu
	@echo ">> building release tarball"
	@$(PROMU) tarball --prefix $(PREFIX) $(BIN_DIR)

docker:
	@echo ">> building docker image $(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)"
	@docker build -t "$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_TAG)" .

promu:
	@GOOS=$(shell uname -s | tr A-Z a-z) \
	        GOARCH=$(subst x86_64,amd64,$(patsubst i%86,386,$(shell uname -m))) \
	        $(GO) get -u github.com/prometheus/promu

ci-reviewdog:                   ## Runs reviewdog checks.
	bin/golangci-lint run -c=.golangci-required.yml --out-format=line-number | bin/reviewdog -f=golangci-lint -level=error -reporter=github-pr-check
	bin/golangci-lint run -c=.golangci.yml --out-format=line-number | bin/reviewdog -f=golangci-lint -level=error -reporter=github-pr-review

travis: build ci-reviewdog test-race codecov tarball docker

codecov: gocoverutil
	@gocoverutil -coverprofile=coverage.txt test $(pkgs)
	@curl -s https://codecov.io/bash | bash -s - -X fix

gocoverutil:
	@$(GO) get -u github.com/AlekSi/gocoverutil

.PHONY: all style format build test vet tarball docker promu
