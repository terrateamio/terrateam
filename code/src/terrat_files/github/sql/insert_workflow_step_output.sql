insert into github_workflow_step_outputs (
    idx,
    ignore_errors,
    payload,
    scope,
    step,
    success,
    work_manifest
) select * from unnest(
    $idx,
    $ignore_errors,
    $payload,
    $scope,
    $step,
    $success,
    $work_manifest
) on conflict (work_manifest, scope, step, idx)
do nothing
