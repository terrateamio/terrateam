# Template directives with ~ strip markers. Shim should flip
# strip_before/after on the record; Menhir may or may not support these
# markers at all or set them to false.
x = "a %{~if y~}b%{~else~}c%{~endif~} d"
y = "e %{~for v in xs~}${v}%{~endfor~} f"
