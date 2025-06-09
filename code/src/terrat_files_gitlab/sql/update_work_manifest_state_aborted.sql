update work_manifests set state = 'aborted', completed_at = now() where id = $id
