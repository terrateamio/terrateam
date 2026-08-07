# Mixed strip markers: one-sided (`~` only before or after).
x = "a ${~b} c"
y = "d ${e~} f"
z = "g %{~if h}i%{endif} j"
w = "k %{if l~}m%{endif} n"
