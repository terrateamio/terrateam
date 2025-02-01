update change_dirs set state = $state
where change = $change and dir_path = $dir_path and workspace = $workspace
