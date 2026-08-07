# Block labels that are keywords (true/false/null). Menhir's block_labels
# rule allows only IDENTIFIER or STRING; keyword tokens like TRUE/FALSE/NULL
# aren't accepted. The shim sees these as TokenIdent and accepts them as
# bare (Id) labels.
resource true name {}
resource null name {}
resource false name {}
