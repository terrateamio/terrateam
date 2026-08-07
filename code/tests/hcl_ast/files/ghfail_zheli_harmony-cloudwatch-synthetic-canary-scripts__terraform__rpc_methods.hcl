locals {
  hosts = [
    "rpc.s0.t.hmny.io",
    "rpc.s1.t.hmny.io"
  ]

  rpc_methods = {
    # smart contract
    "call" : {
      "method" : "hmyv2_call"
      "params" : [
        { "to" : "0x08AE1abFE01aEA60a47663bCe0794eCCD5763c19" },
        370000
      ],
      "result_type" : "string",
      "verify_result" : true
      "expected_result" : "\"0x\""
    },
    "estimate_gas" : {
      "method" : "hmyv2_estimateGas",
      "params" : [
        { "to" : "0x08AE1abFE01aEA60a47663bCe0794eCCD5763c19" },
      ],
      "result_type" : "string",
      "verify_result" : true
      "expected_result" : "\"0x5208\""
    },
    "get_code" : {
      "method" : "hmyv2_getCode"
      "params" : [
        "0x08AE1abFE01aEA60a47663bCe0794eCCD5763c19",
        370000
      ],
      "result_type" : "string",
      "verify_result" : true
      "expected_result" : "\"0x\""
    },
    "get_storage_at" : {
      "method" : "hmyv2_getStorageAt"
      "params" : [
        "0x295a70b2de5e3953354a6a8344e616ed314d7251",
        "0x0",
        370000
      ],
      "result_type" : "string",
      "verify_result" : true
      "expected_result" : "\"0x0000000000000000000000000000000000000000000000000000000000000000\""
    },

    # staking - delegation
    # CloudWatch canary max length is 21
    "delegations_by_delega" : {
      "method" : "hmyv2_getDelegationsByDelegator",
      "params" : [
        "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9"
      ]
      "result_type" : "object",
      "verify_result" : true
      "expected_result" : jsonencode([
        {
          "Undelegations" : [],
          "amount" : 0,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 0,
          "validator_address" : "one1r3kwetfy3ekfah75qaedwlc72npqm2gkayn6ue"
        },
        {
          "Undelegations" : [],
          "amount" : 0,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 0,
          "validator_address" : "one14wyp73qmn3zch98dqnjvu4rprcz79tlrxq3al6"
        },
        {
          "Undelegations" : [],
          "amount" : 0,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 0,
          "validator_address" : "one1kf42rl6yg2avkjsu34ch2jn8yjs64ycn4n9wdj"
        },
        {
          "Undelegations" : [],
          "amount" : 0,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 0,
          "validator_address" : "one18xrw6c8a7hrrpxayflmsgwq9k5rxhfqjgsqdd5"
        }
      ])
    },
    "del_by_del_by_block" : {
      "method" : "hmyv2_getDelegationsByDelegatorByBlockNumber",
      "params" : [
        "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
        3700000
      ]
      "result_type" : "object",
      "verify_result" : true
      "expected_result" : jsonencode([
        {
          "Undelegations" : [],
          "amount" : 6.90098018e+23,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 707732421124633500000,
          "validator_address" : "one1r3kwetfy3ekfah75qaedwlc72npqm2gkayn6ue"
        },
        {
          "Undelegations" : [],
          "amount" : 5.17573513487e+23,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 530186649349346950000,
          "validator_address" : "one14wyp73qmn3zch98dqnjvu4rprcz79tlrxq3al6"
        },
        {
          "Undelegations" : [],
          "amount" : 5.17573e+23,
          "delegator_address" : "one1t593eqff9h2cjxz2k7d6q4cg4zmmgtm9veeyd9",
          "reward" : 519118543630209100000,
          "validator_address" : "one1kf42rl6yg2avkjsu34ch2jn8yjs64ycn4n9wdj"
        }
      ])
    },
    "del_by_validator" : {
      "method" : "hmyv2_getDelegationsByValidator",
      "params" : [
        "one1qk7mp94ydftmq4ag8xn6y80876vc28q7s9kpp7"
      ]
      "result_type" : "object",
      "verify_result" : true
      "expected_result" : jsonencode(local.expected_result["hmyv2_getDelegationsByValidator"])
    },
    # staking - validator
    # test is in all_validator_addresses.js script, the fields in this map are ignored
    "all_validator_address" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : true
      "expected_result" : ""
    },
    # test is in all_validator_info.js script, the fields in this map are ignored
    "all_validator_info" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : true
      "expected_result" : ""
    },
    # test is in all_validator_inf_blo.js script, the fields in this map are ignored
    "all_validator_inf_blo" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : true
      "expected_result" : ""
    },
    # test is in elected_validatoraddr.js script, the fields in this map are ignored
    "elected_validatoraddr" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : true
      "expected_result" : ""
    },
    # test is in validator_information.js script, the fields in this map are ignored
    "validator_information" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : true
      "expected_result" : ""
    },
    # staking - network
    "utility_metric" : {
      "method" : "hmyv2_getCurrentUtilityMetrics",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "median_raw_stake_snap" : {
      "method" : "hmyv2_getMedianRawStakeSnapshot",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "staking_net_info" : {
      "method" : "hmyv2_getStakingNetworkInfo",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "super_commitees" : {
      "method" : "hmyv2_getSuperCommittees",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    # transaction - cross shard
    "cx_receipt_by_has" : {
      "method" : "hmyv2_getCXReceiptByHash",
      "params" : [
        "0xd324cc57280411dfac5a7ec2987d0b83e25e27a3d5bb5d3531262387331d692b"
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "pending_cx_receipts" : {
      "method" : "hmyv2_getPendingCXReceipts",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "resend_cx" : {
      "method" : "hmyv2_resendCx",
      "params" : ["0xd324cc57280411dfac5a7ec2987d0b83e25e27a3d5bb5d3531262387331d692b"],
      "result_type" : "boolean",
      "verify_result" : true
      "expected_result" : "true"
    },
    # transaction - transaction pool
    "pool_stats" : {
      "method" : "hmyv2_getPoolStats",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "pending_staking_t" : {
      "method" : "hmyv2_pendingStakingTransactions",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "pending_transactions" : {
      "method" : "hmyv2_pendingTransactions",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    # transaction - staking
    "stake_error_sink" : {
      "method" : "hmyv2_getCurrentStakingErrorSink",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "stak_tran_by_blo_in" : {
      "method" : "hmyv2_getStakingTransactionByBlockNumberAndIndex",
      "params" : [
        5601505,
        0
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "stak_tran_by_blo_hash" : {
      "method" : "hmyv2_getStakingTransactionByBlockHashAndIndex",
      "params" : [
        "0x1e81ce2e75d670e8c523a7a4fd12179638896e4ff496e24f69e2f075f79a28f6",
        0
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "stak_tran_by_hash" : {
      "method" : "hmyv2_getStakingTransactionByHash",
      "params" : [
        "0x097e58ef5e0a59cac1ca8653793659c9bb69599cb032867c035cdc9cd071483e",
      ],
      "result_type" : "object",
      "verify_result" : true
      "expected_result" : jsonencode({
        "blockHash" : "0xd1d6529a4729388933fa72b980aaff7bda6a49083656af6aee6d248bde09fadc",
        "blockNumber" : 3709557,
        "from" : "one10g7kfque6ew2jjfxxa6agkdwk4wlyjuncp6gwz",
        "gas" : 24476,
        "gasPrice" : 1000000000,
        "hash" : "0x097e58ef5e0a59cac1ca8653793659c9bb69599cb032867c035cdc9cd071483e",
        "msg" : {
          "amount" : 1.108e+21,
          "delegatorAddress" : "one10g7kfque6ew2jjfxxa6agkdwk4wlyjuncp6gwz",
          "validatorAddress" : "one1tc9q6t4sn3gjde00eemkjr2e44jdplhg02r54m"
        },
        "nonce" : 163,
        "r" : "0x6a476d6e9f03fd90acf3dd61710187d393566d79e10ac253c4180802767e596e",
        "s" : "0x71229edc6fad1bf02b1e3d2a7de124716495e8c692cf93aee346c894aaf458fb",
        "timestamp" : 1592728263,
        "transactionIndex" : 0,
        "type" : "Delegate",
        "v" : "0x25"
      })
    },
    # TODO: replace this with a JS test case
    "send_raw_stake_tran" : {
      "method" : "hmyv2_sendRawStakingTransaction",
      "params" : [
        "0xDEADBEEF",
      ],
      "result_type" : "string",
      "verify_result" : true
      "expected_result" : "0xDEADBEEF"
    },
    # transaction - transfer
    "curr_tran_err_sink" : {
      "method" : "hmyv2_getCurrentTransactionErrorSink",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "tran_blk_hash_i" : {
      "method" : "hmyv2_getTransactionByBlockHashAndIndex",
      "params" : [
        "0x77ef489dce6deee69374aa878a67a9cf1f653ec4f7b697bbeed2931669f6be77",
        0
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "tran_by_blk_num_index" : {
      "method" : "hmyv2_getTransactionByBlockNumberAndIndex",
      "params" : [
        3687181,
        0
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "tran_by_hash" : {
      "method" : "hmyv2_getTransactionByHash",
      "params" : [
        "0x41d6e74ff3a7e615080b98fcfb7bce8be7b1ba4a8671e1ba2e9527eb3e1da20d"
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "transaction_receipt" : {
      "method" : "hmyv2_getTransactionReceipt",
      "params" : [
        "0xd324cc57280411dfac5a7ec2987d0b83e25e27a3d5bb5d3531262387331d692b"
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    # test is in send_raw_tran.js script, the fields in this map are ignored
    "send_raw_tran" : {
      "method" : "",
      "params" : [],
      "result_type" : "",
      "verify_result" : false
      "expected_result" : ""
    },

    # blockchain - network
    "block_num" : {
      "method" : "hmyv2_blockNumber",
      "params" : [],
      "result_type" : "number",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "ciculating_supply" : {
      "method" : "hmyv2_getCirculatingSupply",
      "params" : [],
      "result_type" : "string",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "epoch" : {
      "method" : "hmyv2_getEpoch",
      "params" : [],
      "result_type" : "number",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "last_cross_links" : {
      "method" : "hmyv2_getLastCrossLinks",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "leader" : {
      "method" : "hmyv2_getLeader",
      "params" : [],
      "result_type" : "string",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "sharding_struct" : {
      "method" : "hmyv2_getShardingStructure",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "total_supply" : {
      "method" : "hmyv2_getTotalSupply",
      "params" : [],
      "result_type" : "string",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "validator" : {
      "method" : "hmyv2_getValidators",
      "params" : [
        1
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "validator_keys" : {
      "method" : "hmyv2_getValidatorKeys",
      "params" : [
        1
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },

    # blockchain - node
    # endpoint not working atm
    "bad_blocks" : {
      "method" : "hmyv2_getCurrentBadBlocks",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "node_metadata" : {
      "method" : "hmyv2_getNodeMetadata",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "protocol_version" : {
      "method" : "hmyv2_protocolVersion",
      "params" : [],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : 1
    },
    "peer_count" : {
      "method" : "net_peerCount",
      "params" : [],
      "result_type" : "string",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },

    # blockchain - blocks
    "blocks" : {
      "method" : "hmyv2_getBlocks",
      "params" : [
        1,
        2,
        {
          "withSigners" : false,
          "fullTx" : false,
          "inclStaking" : false
        }
      ],
      "result_type" : "object",
      "verify_result" : false
      "expected_result" : jsonencode([
        {
          "difficulty" : 0,
          "epoch" : 0,
          "extraData" : "0x",
          "gasLimit" : 4716988,
          "gasUsed" : 0,
          "hash" : "0x61ce03ef5efa374b0d0d527ea38c3d13cb05cf765a4f898e91a5de1f6b224cdd",
          "logsBloom" : "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          "miner" : "one1gh043zc95e6mtutwy5a2zhvsxv7lnlklkj42ux",
          "mixHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
          "nonce" : 0,
          "number" : 1,
          "parentHash" : "0xb4d158b82ac8a653c42b78697ab1cd0c6a0d9a15ab3bc34130f0b719fb174d2a",
          "receiptsRoot" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
          "size" : 601,
          "stakingTransactions" : [],
          "stateRoot" : "0x8be048c908585bbb6b155324ad8a854484994ab27e5987af134ad036079675bf",
          "timestamp" : 1561736306,
          "transactions" : [],
          "transactionsInEthHash" : [],
          "transactionsRoot" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
          "uncles" : [],
          "viewID" : 0
        },
        {
          "difficulty" : 0,
          "epoch" : 0,
          "extraData" : "0x",
          "gasLimit" : 4721593,
          "gasUsed" : 0,
          "hash" : "0x705e7368bd6a3b61761c92617bc49d9a6108226872473bb9deaa6c995f939c49",
          "logsBloom" : "0x00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
          "miner" : "one1gh043zc95e6mtutwy5a2zhvsxv7lnlklkj42ux",
          "mixHash" : "0x0000000000000000000000000000000000000000000000000000000000000000",
          "nonce" : 0,
          "number" : 2,
          "parentHash" : "0x61ce03ef5efa374b0d0d527ea38c3d13cb05cf765a4f898e91a5de1f6b224cdd",
          "receiptsRoot" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
          "size" : 620,
          "stakingTransactions" : [],
          "stateRoot" : "0x8e90e429b28aea29f6560a6e19eeafcce899bdd16fedca2d1dbfe65b76488d65",
          "timestamp" : 1561736315,
          "transactions" : [],
          "transactionsInEthHash" : [],
          "transactionsRoot" : "0x56e81f171bcc55a6ff8345e692c0f86e5b48e01b996cadc001622fb5e363b421",
          "uncles" : [],
          "viewID" : 1
        }
      ])
    },
    "blo_by_num" : {
      "method" : "hmyv2_getBlockByNumber",
      "params" : [
        1,
        {
          "fullTx" : true,
          "inclTx" : true,
          "InclStaking" : true
        }
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "blo_by_hash" : {
      "method" : "hmyv2_getBlockByHash",
      "params" : [
        "0x61ce03ef5efa374b0d0d527ea38c3d13cb05cf765a4f898e91a5de1f6b224cdd",
        {
          "fullTx" : true,
          "inclTx" : true,
          "InclStaking" : true
        }
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "blo_by_signer" : {
      "method" : "hmyv2_getBlockSigners",
      "params" : [
        1
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "blo_singer_keys" : {
      "method" : "hmyv2_getBlockSignerKeys",
      "params" : [1],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "blo_tran_count_bynum" : {
      "method" : "hmyv2_getBlockTransactionCountByNumber",
      "params" : [1],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : "0"
    },
    "blo_tran_count_byhash" : {
      "method" : "hmyv2_getBlockTransactionCountByHash",
      "params" : ["0x61ce03ef5efa374b0d0d527ea38c3d13cb05cf765a4f898e91a5de1f6b224cdd"],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : 0
    },
    "header_by_num" : {
      "method" : "hmyv2_getHeaderByNumber",
      "params" : [1],
      "result_type" : "object",
      "verify_result" : true
      "expected_result" : jsonencode({
        "blockHash" : "0x61ce03ef5efa374b0d0d527ea38c3d13cb05cf765a4f898e91a5de1f6b224cdd",
        "blockNumber" : 1,
        "crossLinks" : [],
        "epoch" : 0,
        "lastCommitBitmap" : "",
        "lastCommitSig" : "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "leader" : "one1gh043zc95e6mtutwy5a2zhvsxv7lnlklkj42ux",
        "shardID" : 0,
        "timestamp" : "2019-06-28 15:38:26 +0000 UTC",
        "unixtime" : 1561736306,
        "viewID" : 0
      })
    },
    "latest_chain_header" : {
      "method" : "hmyv2_getLatestChainHeaders",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "latest_header" : {
      "method" : "hmyv2_latestHeader",
      "params" : [],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },

    # account
    "balance" : {
      "method" : "hmyv2_getBalance"
      "params" : ["one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt"],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : 12001989979000000000000
    },
    "balance_by_blo_num" : {
      "method" : "hmyv2_getBalanceByBlockNumber",
      "params" : ["one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt", 1],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : 0
    },
    "staking_tran_count" : {
      "method" : "hmyv2_getStakingTransactionsCount",
      "params" : ["one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt", "SENT"],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : 0
    },
    "staking_tran_history" : {
      "method" : "hmyv2_getStakingTransactionsHistory",
      "params" : [
        {
          "address" : "one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt",
          "pageIndex" : 0,
          "pageSize" : 1,
          "fullTx" : true,
          "txType" : "ALL",
          "order" : "ASC"
        }
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    },
    "transactions_count" : {
      "method" : "hmyv2_getTransactionsCount",
      "params" : ["one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt", "SENT"],
      "result_type" : "number",
      "verify_result" : true
      "expected_result" : "0"
    },
    "transactions_history" : {
      "method" : "hmyv2_getTransactionsHistory",
      "params" : [
        {
          "address" : "one15vlc8yqstm9algcf6e94dxqx6y04jcsqjuc3gt",
          "pageIndex" : 0,
          "pageSize" : 1,
          "fullTx" : true,
          "txType" : "ALL",
          "order" : "ASC"
        }
      ],
      "result_type" : "object",
      "verify_result" : false
      # "expected_result" will be ignored when "verify_result" is false
      "expected_result" : "0"
    }

  }
}
