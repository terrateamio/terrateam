.PHONY: terrat-api terrat-repo-config terrat-webhooks

all: .merlin

.merlin: pds.conf
	touch dune dune-project dune-workspace
	pds -f | merlin-of-pds > .merlin

pds.mk: pds.conf
	pds

terrat-api: release_openapi_cli
	rm -f ./src/terrat_api/*.ml
	env OCAMLRUNPARAM=b ./build/release/openapi_cli/openapi_cli.native convert --input ../docs/terrat/api.json --name "terrat_api" --output-dir ./src/terrat_api
	find src/terrat_api  -type f -exec ocamlformat -i '{}' \;

terrat-repo-config: release_json_schema_hooks_cli
	rm -f ./src/terrat_repo_config/*.ml
	env OCAMLRUNPARAM=b ./build/release/json_schema_hooks_cli/json_schema_hooks_cli.native convert --input ../docs/terrat/config-schema.json --name terrat_repo_config --output-dir=./src/terrat_repo_config/
	find src/terrat_repo_config/ -type f -exec ocamlformat -i '{}' \;

terrat-webhooks: release_json_schema_hooks_cli
	rm -f ./src/terrat_github_webhooks/*.ml
	env OCAMLRUNPARAM=b ./build/release/json_schema_hooks_cli/json_schema_hooks_cli.native convert -i ../docs/github_webhooks/terrat-schema.json -n terrat_github_webhooks --output-dir ./src/terrat_github_webhooks/ --non-strict-records
	find src/terrat_github_webhooks/ -type f -exec ocamlformat -i '{}' \;

github-api: release_openapi_cli
	rm -rf src/githubc2
	mkdir -p src/githubc2
	env OCAMLRUNPARAM=b ./build/release/openapi_cli/openapi_cli.native convert --input ../docs/github_api/api.github.com.json --name "githubc2" --output-dir ./src/githubc2/
	find src/githubc2/ -type f -exec ocamlformat -i '{}' \;

-include pds.mk
