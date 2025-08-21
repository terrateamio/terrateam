.PHONY: terrat-api terrat-repo-config terrat-webhooks gitlab-webhooks
.PHONY: gitlab-api github-api
.PHONY: terrat release-terrat debug-terrat
.PHONY: pins-file

all: .merlin

.merlin: pds.conf
	touch dune dune-project dune-workspace
	pds -f | merlin-of-pds > .merlin

pds.mk: pds.conf $(wildcard src/*/*) $(wildcard test/*/*)
	pds -d

terrat-schemas: terrat-api terrat-repo-config terrat-webhooks gitlab-api gitlab-webhooks

terrat: release-terrat debug-terrat

test-terrat: test-release-terrat test-debug-terrat

test-terrat: release_terrat_vcs_api_nyi release_terrat_vcs_provider2_nyi release_terrat_vcs_service_nyi

test-terrat: debug_terrat_vcs_api_nyi debug_terrat_vcs_provider2_nyi debug_terrat_vcs_service_nyi

release-terrat: release_terrat_oss release_terrat_ee release_iris

# This ensures that iris is built last, if you're doing backend development this
# is nice for speeding up the feedback loop.
release_iris: release_terrat_oss release_terrat_ee

debug-terrat: debug_terrat_oss debug_terrat_ee debug_iris

test-debug-terrat: test-debug_abb_fut test-debug_abb_future_combinators

test-release-terrat: test-release_abb_flow

test-release-terrat: test-release_terrat test-release_terrat_github_webhooks test-release_terrat_sql_of_tag_query

test-release-terrat: test-release_jsonu

test-release-terrat: test-release_abb_cache

release-terrat: release_terrat_code_indexer

debug-terrat: debug_terrat_code_indexer

terrat-api: debug_openapi_cli release_openapi_cli
	jq -S . < ../api_schemas/terrat/api.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/api.json
	rm -f ./src/terrat_api/*.ml
	env OCAMLRUNPARAM=b ./build/debug/openapi_cli/openapi_cli.native convert --non-strict-records --input ../api_schemas/terrat/api.json --name "terrat_api" --output-dir ./src/terrat_api
	find src/terrat_api  -type f -exec ocamlformat -i '{}' \;

terrat-repo-config: debug_json_schema_hooks_cli release_json_schema_hooks_cli
	jq -S . < ../api_schemas/terrat/config-schema.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/terrat/config-schema.json
	rm -f ./src/terrat_repo_config/*.ml
	env OCAMLRUNPARAM=b ./build/debug/json_schema_hooks_cli/json_schema_hooks_cli.native convert --input ../api_schemas/terrat/config-schema.json --name terrat_repo_config --output-dir=./src/terrat_repo_config/
	find src/terrat_repo_config/ -type f -exec ocamlformat -i '{}' \;

terrat-webhooks: debug_json_schema_hooks_cli release_json_schema_hooks_cli
	jq -S . < ../api_schemas/github_webhooks/terrat-schema.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/github_webhooks/terrat-schema.json
	rm -f ./src/terrat_github_webhooks/*.ml
	env OCAMLRUNPARAM=b ./build/debug/json_schema_hooks_cli/json_schema_hooks_cli.native convert -i ../api_schemas/github_webhooks/terrat-schema.json -n terrat_github_webhooks --output-dir ./src/terrat_github_webhooks/ --non-strict-records
	find src/terrat_github_webhooks/ -type f -exec ocamlformat -i '{}' \;

github-api: debug_openapi_cli release_openapi_cli
	jq -S . < ../api_schemas/github_api/api.github.com.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/github_api/api.github.com.json
	rm -rf src/githubc2
	mkdir -p src/githubc2
	env OCAMLRUNPARAM=b ./build/debug/openapi_cli/openapi_cli.native convert --non-strict-records --input ../api_schemas/github_api/api.github.com.json --name "githubc2" --output-dir ./src/githubc2/
	find src/githubc2/ -type f -exec ocamlformat -i '{}' \;

gitlab-api: debug_openapi_cli release_openapi_cli
	jq -S . < ../api_schemas/gitlab_api/api.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/gitlab_api/api.json
	rm -rf src/gitlabc
	mkdir -p src/gitlabc
	env OCAMLRUNPARAM=b ./build/debug/openapi_cli/openapi_cli.native convert --non-strict-records --input ../api_schemas/gitlab_api/api.json --name "gitlabc" --output-dir ./src/gitlabc/
	find src/gitlabc/ -type f -exec ocamlformat -i '{}' \;

gitlab-webhooks: debug_json_schema_hooks_cli release_json_schema_hooks_cli
	jq -S . < ../api_schemas/gitlab_api/webhooks.json > /tmp/$$$$.json && mv /tmp/$$$$.json ../api_schemas/gitlab_api/webhooks.json
	rm -f ./src/gitlab_webhooks/*.ml
	env OCAMLRUNPARAM=b ./build/debug/json_schema_hooks_cli/json_schema_hooks_cli.native convert -i ../api_schemas/gitlab_api/webhooks.json -n gitlab_webhooks --output-dir ./src/gitlab_webhooks/ --non-strict-records
	find src/gitlab_webhooks/ -type f -exec ocamlformat -i '{}' \;

# This assumes that the necessary work has been done using hll generate to make
# a package called monorepo that is available via opam
pins-file:
	opam list --required-by=monorepo --columns name,version --short | grep -v pds | grep -v ocurl | awk '{print $1, "=", "\"" $2 "\""}' | sort > hll.pins

-include pds.mk
