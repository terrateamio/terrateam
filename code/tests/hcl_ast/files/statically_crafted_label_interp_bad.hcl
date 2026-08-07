# Block label containing a template interpolation. Shim rejects with
# "Template sequences are not allowed in this string"; Menhir keeps
# the raw `${...}` bytes in the label's string value.
resource "aws_instance" "prefix_${suffix}" {
  ami = "abc"
}
