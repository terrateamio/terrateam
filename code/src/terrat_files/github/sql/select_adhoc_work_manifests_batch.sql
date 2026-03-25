select
  awm.work_manifest,
  awm.branch
from adhoc_work_manifests as awm
where awm.work_manifest = ANY($ids)
