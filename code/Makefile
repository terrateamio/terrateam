.PHONY: terrat-api terrat-repo-config terrat-webhooks
.PHONY: terrat release-terrat debug-terrat

all: .merlin

.merlin: pds.conf
	touch dune dune-project dune-workspace
	pds -f | merlin-of-pds > .merlin

pds.mk: pds.conf $(wildcard src/*/*) $(wildcard test/*/*)
	pds -d

terrat-schemas: terrat-api terrat-repo-config terrat-webhooks

terrat: release-terrat debug-terrat

release-terrat: release_terrat_oss release_terrat_ee release_terrat_ui_files

debug-terrat: debug_terrat_oss debug_terrat_ee debug_terrat_ui_files

debug-terrat: test-debug_abb_fut test-debug_abb_future_combinators

release-terrat: test-release_abb_flow

release-terrat: test-release_terrat test-release_terrat_github_webhooks test-release_terrat_sql_of_tag_query

release-terrat: test-release_jsonu

release-terrat: test-release_abb_cache

release-terrat: release_terrat_code_indexer

debug-terrat: debug_terrat_code_indexer

terrat-api: release_openapi_cli
	rm -f ./src/terrat_api/*.ml
	env OCAMLRUNPARAM=b ./build/release/openapi_cli/openapi_cli.native convert --input ../api_schemas/terrat/api.json --name "terrat_api" --output-dir ./src/terrat_api
	find src/terrat_api  -type f -exec ocamlformat -i '{}' \;
	pds

terrat-repo-config: release_json_schema_hooks_cli
	rm -f ./src/terrat_repo_config/*.ml
	env OCAMLRUNPARAM=b ./build/release/json_schema_hooks_cli/json_schema_hooks_cli.native convert --input ../api_schemas/terrat/config-schema.json --name terrat_repo_config --output-dir=./src/terrat_repo_config/
	find src/terrat_repo_config/ -type f -exec ocamlformat -i '{}' \;
	pds

terrat-webhooks: release_json_schema_hooks_cli
	rm -f ./src/terrat_github_webhooks/*.ml
	env OCAMLRUNPARAM=b ./build/release/json_schema_hooks_cli/json_schema_hooks_cli.native convert -i ../api_schemas/github_webhooks/terrat-schema.json -n terrat_github_webhooks --output-dir ./src/terrat_github_webhooks/ --non-strict-records
	find src/terrat_github_webhooks/ -type f -exec ocamlformat -i '{}' \;
	pds

github-api: release_openapi_cli
	rm -rf src/githubc2
	mkdir -p src/githubc2
	env OCAMLRUNPARAM=b ./build/release/openapi_cli/openapi_cli.native convert --non-strict-records --input ../api_schemas/github_api/api.github.com.json --name "githubc2" --output-dir ./src/githubc2/
	find src/githubc2/ -type f -exec ocamlformat -i '{}' \;
	pds

-include pds.mk
