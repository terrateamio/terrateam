insert into job_work_manifests (job_id, work_manifest) values ($job, $work_manifest)
on conflict (job_id, work_manifest) do nothing
