This directory contains the API and Webhook JSON schemas for GitLab.

It started out as trying to be a mechanical translation from the existing GitLab OpenAPI schema to something Terrateam could consume however there were a few issues:

1. The OpenAPI scheme is not very accurate.  It contains many incorrect type specificatiosn.
2. The OpenAPI schema is not a valid OpenAPI schema, as far as I can tell.  Maybe my understanding of OpenAPI is incorrect but the GitLab schema uses multiple annotations that I do not believe are valid.
3. The schema has a lot of content we are not interested in.

Initial translations from the YAML to `api.json` were done via software.  Specifically running the following program:

```
python extract_paths.py openapi_v2.json --prefixes '/api/v3/' '/api/v4/projects/' '/api/v4/users' '/api/v4/version' '/api/v4/user' '/api/v4/runners' '/api/v4/groups' '/api/v4/applications' '/api/v4/admin' | jq -S . > api.json
```

But then that was manually modified quite a bit.

The current layout:

1. `openapi_v2.yaml` - This is the version of GitLab's schema that everything else was generated from.
2. `api.orig.json` - This was created via a mix of manual and automatic transformations from `openapi_v2.yaml`.  It contains, partially incorrect, but extensive schema definitions.
3. `api.json` - This is the version used in production.  It has everything removed that is not necessary.

This is to say: when looking to add new GitLab functionality, **DO NOT** use `api.json` to determine if GitLab has a valid API for it.  Instead look at `openapi_v2.yaml` and `api.orig.json`, and then manually bring that schema into `api.json`.
