SHELL := /bin/bash
.DEFAULT_GOAL := source-registry

.PHONY: all setup-environment source-registry paper

all: source-registry

setup-environment:
	$(MAKE) -C tasks/setup_environment/code

source-registry:
	$(MAKE) -C tasks/source_registry/code

paper:
	$(MAKE) -C paper
