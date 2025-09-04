This exists because the official github schema does not necessarily correspond
to what github sends us, so this is the modified schema.

The `api.github.com.json.orig` is whatever version the `api.github.com.json` was
based off of.  This exists because we modify the API file because GitHub does
not always follow it and can thus be used as a three-way merge when updating the
`api.github.com.json` file to the latest version.


BE SURE TO sort the files when comparing with `jq -S .`.  This ensures
everything is in a deterministic order before trying to do any merging.
