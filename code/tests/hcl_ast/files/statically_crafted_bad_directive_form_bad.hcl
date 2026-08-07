# Invalid directive forms that Menhir's classifier doesn't recognize
# and so keeps them as literal text. The shim's template parser rejects
# these with a diagnostic.
a = "%{while true}loop%{endwhile}"
b = "%{unknown_keyword}body"
