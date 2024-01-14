false = { for foo in false : false => false if )
---
false = { for foo in foo : foo => foo if )
---
false = { for foo in foo : foo => foo if }
---
false = { for foo in foo : foo => foo if ]
---
false = { for foo in foo : foo => foo if *
---
false = { for foo in foo : foo => foo if +
---
false = { for foo in foo : foo => foo if :
