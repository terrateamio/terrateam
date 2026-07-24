# Intentionally empty in the terrateam repo.
#
# code/Makefile is shared verbatim with the stategraph monorepo, and it ends with
# `include stategraph.mk`. In the monorepo that file defines the stategraph-only
# build targets; terrateam has none, but the file must exist so the shared
# Makefile's `include` resolves. Each repo owns its own copy (copybara does not
# sync this file) -- do not delete it.
