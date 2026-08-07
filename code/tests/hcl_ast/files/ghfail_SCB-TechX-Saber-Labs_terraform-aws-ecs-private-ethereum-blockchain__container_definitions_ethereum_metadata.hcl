locals {

  // For S3 related operations
  s3_revision_folder = "${local.ethereum_bucket}/rev_$TASK_REVISION"

  normalized_host_ip = "ip_$(echo $HOST_IP | sed -e 's/\\./_/g')"

  metadata_commands = [

    "set -e",
    "echo Wait until Node Key is ready ...",
    "while [ ! -f \"${local.node_id_file}\" ]; do sleep 1; done",
    "yum install jq -y",
    "export TASK_REVISION=$(curl -s 169.254.170.2/v2/metadata | jq '.Revision' -r)",
    "echo \"Task Revision: $TASK_REVISION\"",
    "echo $TASK_REVISION > ${local.task_revision_file}",
    "export HOST_IP=$(curl -s 169.254.170.2/v2/metadata | jq '.Containers[] | select(.Name == \"${local.metadata_container_name}\") | .Networks[] | select(.NetworkMode == \"awsvpc\") | .IPv4Addresses[0]' -r )",
    "echo \"Host IP: $HOST_IP\"",
    "echo $HOST_IP > ${local.host_ip_file}",
    "export TASK_ARN=$(curl -s 169.254.170.2/v2/metadata | jq -r '.TaskARN')",
    "aws ecs describe-tasks --cluster ${local.ecs_cluster_name} --tasks $TASK_ARN | jq -r '.tasks[0] | .group' > ${local.service_file}",
    "mkdir -p ${local.hosts_folder}",
    "mkdir -p ${local.node_ids_folder}",
    "mkdir -p ${local.accounts_folder}",
    "aws s3 cp ${local.node_id_file} s3://${local.s3_revision_folder}/nodeids/${local.normalized_host_ip}",
    "aws s3 cp ${local.host_ip_file} s3://${local.s3_revision_folder}/hosts/${local.normalized_host_ip}",
    "aws s3 cp ${local.account_address_file} s3://${local.s3_revision_folder}/accounts/${local.normalized_host_ip}",

    // Gather all IPs
    "count=0; while [ $count -lt ${var.number_of_nodes} ]; do count=$(ls ${local.hosts_folder} | grep ^ip | wc -l); aws s3 cp --recursive s3://${local.s3_revision_folder}/hosts ${local.hosts_folder} > /dev/null 2>&1 | echo \"Wait for other containers to report their IPs ... $count/${var.number_of_nodes}\"; sleep 1; done",

    "echo \"All containers have reported their IPs\"",

    // Gather all Accounts
    "count=0; while [ $count -lt ${var.number_of_nodes} ]; do count=$(ls ${local.accounts_folder} | grep ^ip | wc -l); aws s3 cp --recursive s3://${local.s3_revision_folder}/accounts ${local.accounts_folder} > /dev/null 2>&1 | echo \"Wait for other nodes to report their accounts ... $count/${var.number_of_nodes}\"; sleep 1; done",

    "echo \"All nodes have registered accounts\"",

    // Gather all Node IDs
    "count=0; while [ $count -lt ${var.number_of_nodes} ]; do count=$(ls ${local.node_ids_folder} | grep ^ip | wc -l); aws s3 cp --recursive s3://${local.s3_revision_folder}/nodeids ${local.node_ids_folder} > /dev/null 2>&1 | echo \"Wait for other nodes to report their IDs ... $count/${var.number_of_nodes}\"; sleep 1; done",

    "echo \"All nodes have registered their IDs\"",

    // Prepare Genesis file
    "alloc=\"\"; for f in `ls ${local.accounts_folder}`; do address=$(cat ${local.accounts_folder}/$f); alloc=\"$alloc,\\\"$address\\\": { \"balance\": \"\\\"1000000000000000000000000000\\\"\"}\"; done",
    "if [ ${length(var.initial_eth_allocations)} -gt 0 ]; then alloc=\"$alloc,${replace(replace(replace(replace(jsonencode(var.initial_eth_allocations), "{", "\\\""), "}", "000000000000000000\\\"}"), ",", "000000000000000000\\\"},\\\""), ":", "\\\" : { \\\"balance\\\": \\\"")}\"; fi",
    "alloc=\"{$${alloc:1}}\"",
    "extraData=\"\\\"0x0000000000000000000000000000000000000000000000000000000000000000\\\"\"",
    "all=\"0x0000000000000000000000000000000000000000000000000000000000000000\"; for f in `ls ${local.accounts_folder}`; do address=$(cat ${local.accounts_folder}/$f); all=\"$all$(echo $address)\"; done;all=\"$all$(echo 0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000)\";",
    "echo clique signer Addresses: $all",
    "extraData=\"\\\"$(echo $all)\\\"\"",
    "echo '${replace(jsonencode(local.genesis), "/\"(true|false|[0-9]+)\"/", "$1")}' | jq \". + { alloc : $alloc, extraData: $extraData } | .config=.config + {clique: {epoch: 30000, period: 1} }\" > ${local.genesis_file}",
    "cat ${local.genesis_file}",

    // Write status
    "echo \"Done!\" > ${local.metadata_container_status_file}",

  ]

  metadata_container_definition = {

    name      = local.metadata_container_name
    image     = var.aws_cli_docker_image
    essential = "false"

    logConfiguration = {
      logDriver = "awslogs"

      options = {
        awslogs-group         = aws_cloudwatch_log_group.go_ethereum.name
        awslogs-region        = var.region
        awslogs-stream-prefix = "logs"
      }
    }

    mountPoints = [
      {
        sourceVolume  = local.shared_volume_name
        containerPath = local.shared_volume_container_path
      },
    ]

    environments = []

    portMappings = []

    volumesFrom = [
      {
        sourceContainer = local.bootstrap_container_name
      },
    ]

    healthCheck = {
      interval    = 30
      retries     = 10
      timeout     = 60
      startPeriod = 300

      command = [
        "CMD-SHELL",
        "[ -f ${local.metadata_container_status_file} ];",
      ]
    }

    entryPoint = [
      "/bin/sh",
      "-c",
      join("\n", local.metadata_commands),
    ]

    dockerLabels = "${local.common_tags}"

    cpu = 0
  }
}