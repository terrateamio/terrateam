.PHONY: all terrat
.PHONY: terrat_oss terrat_ee terrat_code_indexer ttm iris
.PHONY: test-terrat
.PHONY: terrat-schemas
.PHONY: terrat-api terrat-repo-config terrat-capabilities terrat-webhooks
.PHONY: terrat-job-context terrat-job
.PHONY: github-api gitlab-api gitlab-webhooks
.PHONY: clean

# Disable make-level parallelism. Every target here is a single `dune
# build` invocation, and dune holds a workspace lock — so running two
# goals concurrently (`make -j foo bar`) just serialises on the lock at
# best, fails at worst. Dune's own scheduler handles all the parallelism
# that actually matters within each invocation, so we lose nothing here.
.NOTPARALLEL:

# Dune lives at the repo root so that `(dirs code api_schemas)` can reach
# the api_schemas/ tree. All commands here delegate to dune, invoked from
# the parent directory.
# Profile selection is centralised: dune-workspace pins `(profile release)`
# as the default.
# No target here passes --profile explicitly.
DUNE := dune
ROOT := $(CURDIR)/..

all: terrat

# Aggregate target: builds all server binaries, the UI assets, and ttm in
# a single dune invocation (the @code/terrat alias is defined in
# code/dune). One invocation matters because dune holds a workspace lock —
# listing the sub-targets as make prerequisites would let `make -j`
# launch them in parallel and the second dune call would block on the
# first. Dune's own scheduler parallelises within the single call.
terrat:
	cd $(ROOT) && $(DUNE) build @code/terrat

# Per-binary targets, useful for narrowing dev iteration to one server.
terrat_oss:
	cd $(ROOT) && $(DUNE) build code/src/terrat_oss/terrat_oss.exe

terrat_ee:
	cd $(ROOT) && $(DUNE) build code/src/terrat_ee/terrat_ee.exe

terrat_code_indexer:
	cd $(ROOT) && $(DUNE) build code/src/terrat_code_indexer/terrat_code_indexer.exe

ttm:
	cd $(ROOT) && $(DUNE) build code/src/ttm/ttm.exe

# UI assets (iris). Built last so backend dev iteration is fast.
iris:
	cd $(ROOT) && $(DUNE) build @code/src/iris/all

# Tests. Tests are declared via `(test ...)` / `(tests ...)` stanzas
# alongside the code they cover.
test-terrat:
	cd $(ROOT) && $(DUNE) runtest code/tests/

# Schema regenerators. Each normalises the source JSON, wipes the
# generated directory, runs the generator, then formats the output.
#
# Sub-targets are invoked sequentially via recursive $(MAKE) rather than
# listed as prerequisites: each one calls `dune build` for its generator
# and dune holds a workspace lock, so `make -j` over prerequisites would
# serialise on the lock at best, fail at worst. Recipe lines run
# sequentially regardless of -j, which is what we want here.
terrat-schemas:
	$(MAKE) terrat-api
	$(MAKE) terrat-repo-config
	$(MAKE) terrat-webhooks
	$(MAKE) terrat-capabilities
	$(MAKE) terrat-job-context
	$(MAKE) terrat-job
	$(MAKE) gitlab-api
	$(MAKE) gitlab-webhooks
	$(MAKE) github-api

terrat-api:
	cd $(ROOT) && $(DUNE) build code/src/openapi_cli/openapi_cli.exe
	jq -S . < ../api_schemas/terrat/api.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/api.json
	rm -f ./src/terrat_api/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/openapi_cli/openapi_cli.exe \
	  convert --non-strict-records --input ../api_schemas/terrat/api.json --name terrat_api --output-dir ./src/terrat_api
	find src/terrat_api -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

terrat-repo-config:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/terrat/config-schema.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/config-schema.json
	rm -f ./src/terrat_repo_config/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert --input ../api_schemas/terrat/config-schema.json --name terrat_repo_config --output-dir=./src/terrat_repo_config/
	find src/terrat_repo_config/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

terrat-capabilities:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/terrat/capabilities.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/capabilities.json
	rm -f ./src/terrat_access_token_caps/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert --input ../api_schemas/terrat/capabilities.json --name terrat_access_token_caps --output-dir=./src/terrat_access_token_caps/
	find src/terrat_access_token_caps/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

terrat-webhooks:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/github_webhooks/terrat-schema.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/github_webhooks/terrat-schema.json
	rm -f ./src/terrat_github_webhooks/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert -i ../api_schemas/github_webhooks/terrat-schema.json -n terrat_github_webhooks --output-dir ./src/terrat_github_webhooks/ --non-strict-records
	find src/terrat_github_webhooks/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

terrat-job-context:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/terrat/job_context.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/job_context.json
	rm -f ./src/terrat_job_context_param/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert --input ../api_schemas/terrat/job_context.json --name terrat_job_context_param --output-dir=./src/terrat_job_context_param/
	find src/terrat_job_context_param/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

terrat-job:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/terrat/job.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/job.json
	rm -f ./src/terrat_job_type/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert --input ../api_schemas/terrat/job.json --name terrat_job_type --output-dir=./src/terrat_job_type/
	find src/terrat_job_type/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

github-api:
	cd $(ROOT) && $(DUNE) build code/src/openapi_cli/openapi_cli.exe
	jq -S . < ../api_schemas/github_api/api.github.com.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/github_api/api.github.com.json
	mkdir -p src/githubc2
	rm -f src/githubc2/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/openapi_cli/openapi_cli.exe \
	  convert --non-strict-records --input ../api_schemas/github_api/api.github.com.json --name githubc2 --output-dir ./src/githubc2/
	find src/githubc2/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

gitlab-api:
	cd $(ROOT) && $(DUNE) build code/src/openapi_cli/openapi_cli.exe
	jq -S . < ../api_schemas/gitlab_api/api.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/gitlab_api/api.json
	mkdir -p src/gitlabc
	rm -f src/gitlabc/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/openapi_cli/openapi_cli.exe \
	  convert --non-strict-records --input ../api_schemas/gitlab_api/api.json --name gitlabc --output-dir ./src/gitlabc/
	find src/gitlabc/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

gitlab-webhooks:
	cd $(ROOT) && $(DUNE) build code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe
	jq -S . < ../api_schemas/gitlab_api/webhooks.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/gitlab_api/webhooks.json
	rm -f ./src/gitlab_webhooks/*.ml
	env OCAMLRUNPARAM=b $(ROOT)/_build/default/code/src/json_schema_hooks_cli/json_schema_hooks_cli.exe \
	  convert -i ../api_schemas/gitlab_api/webhooks.json -n gitlab_webhooks --output-dir ./src/gitlab_webhooks/ --non-strict-records
	find src/gitlab_webhooks/ -type f \( -name '*.ml' -o -name '*.mli' \) -exec ocamlformat -i '{}' \;

clean:
	cd $(ROOT) && $(DUNE) clean
