module String = struct
  let mem = CCList.mem ~eq:CCString.equal
  let sort = CCList.sort CCString.compare
  let sort_uniq = CCList.sort_uniq ~cmp:CCString.compare
  let equal = CCList.equal CCString.equal
  let uniq = CCList.uniq ~eq:CCString.equal
  let remove key l = CCList.remove ~eq:CCString.equal ~key l
  let assoc_opt k l = CCList.assoc_opt ~eq:CCString.equal k l
  let mem_assoc k l = CCList.mem_assoc ~eq:CCString.equal k l
  let sort_assoc l = CCList.sort (fun (a, _) (b, _) -> CCString.compare a b) l
end

module Uuidm = struct
  let mem = CCList.mem ~eq:Uuidm.equal
end
