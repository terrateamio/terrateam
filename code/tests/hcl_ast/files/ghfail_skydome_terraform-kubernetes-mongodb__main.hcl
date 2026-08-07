resource "kubernetes_config_map" "mongodb_replicaset_init" {
  metadata {
    name      = "${var.name}-mongodb-replicaset-init"
    namespace = var.namespace

    labels = {
      app     = "mongodb-replicaset"
      release = var.name
    }
  }

  data = {
    "on-start.sh" = "#!/usr/bin/env bash\n\n# Copyright 2018 The Kubernetes Authors. All rights reserved.\n#\n# Licensed under the Apache License, Version 2.0 (the \"License\");\n# you may not use this file except in compliance with the License.\n# You may obtain a copy of the License at\n#\n#     http://www.apache.org/licenses/LICENSE-2.0\n#\n# Unless required by applicable law or agreed to in writing, software\n# distributed under the License is distributed on an \"AS IS\" BASIS,\n# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.\n# See the License for the specific language governing permissions and\n# limitations under the License.\n\nset -e pipefail\n\nport=27017\nreplica_set=\"$REPLICA_SET\"\nscript_name=$${0##*/}\nSECONDS=0\ntimeout=\"$${TIMEOUT:-900}\"\n\nif [[ \"$AUTH\" == \"true\" ]]; then\n    admin_user=\"$ADMIN_USER\"\n    admin_password=\"$ADMIN_PASSWORD\"\n    admin_creds=(-u \"$admin_user\" -p \"$admin_password\")\n    if [[ \"$METRICS\" == \"true\" ]]; then\n        metrics_user=\"$METRICS_USER\"\n        metrics_password=\"$METRICS_PASSWORD\"\n    fi\n    auth_args=(\"--auth\" \"--keyFile=/data/configdb/key.txt\")\nfi\n\nlog() {\n    local msg=\"$1\"\n    local timestamp\n    timestamp=$(date --iso-8601=ns)\n    echo \"[$timestamp] [$script_name] $msg\" 2>&1 | tee -a /work-dir/log.txt 1>&2\n}\n\nretry_until() {\n    local host=\"$${1}\"\n    local command=\"$${2}\"\n    local expected=\"$${3}\"\n    local creds=(\"$${admin_creds[@]}\")\n\n    # Don't need credentials for admin user creation and pings that run on localhost\n    if [[ \"$${host}\" =~ ^localhost ]]; then\n        creds=()\n    fi\n\n    until [[ $(mongo admin --host \"$${host}\" \"$${creds[@]}\" \"$${ssl_args[@]}\" --quiet --eval \"$${command}\") == \"$${expected}\" ]]; do\n        sleep 1\n\n        if (! ps \"$${pid}\" &>/dev/null); then\n            log \"mongod shutdown unexpectedly\"\n            exit 1\n        fi\n        if [[ \"$${SECONDS}\" -ge \"$${timeout}\" ]]; then\n            log \"Timed out after $${timeout}s attempting to bootstrap mongod\"\n            exit 1\n        fi\n\n        log \"Retrying $${command} on $${host}\"\n    done\n}\n\nshutdown_mongo() {\n    local host=\"$${1:-localhost}\"\n    local args='force: true'\n    log \"Shutting down MongoDB ($args)...\"\n    if (! mongo admin --host \"$${host}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --eval \"db.shutdownServer({$args})\"); then\n      log \"db.shutdownServer() failed, sending the terminate signal\"\n      kill -TERM \"$${pid}\"\n    fi\n}\n\ninit_mongod_standalone() {\n    if [[ ! -f /init/initMongodStandalone.js ]]; then\n        log \"Skipping init mongod standalone script\"\n        return 0\n    elif [[ -z \"$(ls -1A /data/db)\" ]]; then\n        log \"mongod standalone script currently not supported on initial install\"\n        return 0\n    fi\n\n    local port=\"27018\"\n    log \"Starting a MongoDB instance as standalone...\"\n    mongod --config /data/configdb/mongod.conf --dbpath=/data/db \"$${auth_args[@]}\" --port \"$${port}\" --bind_ip=0.0.0.0 2>&1 | tee -a /work-dir/log.txt 1>&2 &\n    export pid=$!\n    trap shutdown_mongo EXIT\n    log \"Waiting for MongoDB to be ready...\"\n    retry_until \"localhost:$${port}\" \"db.adminCommand('ping').ok\" \"1\"\n    log \"Running init js script on standalone mongod\"\n    mongo admin --port \"$${port}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" /init/initMongodStandalone.js\n    shutdown_mongo \"localhost:$${port}\"\n}\n\nmy_hostname=$(hostname)\nlog \"Bootstrapping MongoDB replica set member: $my_hostname\"\n\nlog \"Reading standard input...\"\nwhile read -ra line; do\n    if [[ \"$${line}\" == *\"$${my_hostname}\"* ]]; then\n        service_name=\"$line\"\n    fi\n    peers=(\"$${peers[@]}\" \"$line\")\ndone\n\n# Generate the ca cert\nca_crt=/data/configdb/tls.crt\nif [ -f \"$ca_crt\"  ]; then\n    log \"Generating certificate\"\n    ca_key=/data/configdb/tls.key\n    pem=/work-dir/mongo.pem\n    ssl_args=(--ssl --sslCAFile \"$ca_crt\" --sslPEMKeyFile \"$pem\")\n\n# Move into /work-dir\npushd /work-dir\n\ncat >openssl.cnf <<EOL\n[req]\nreq_extensions = v3_req\ndistinguished_name = req_distinguished_name\n[req_distinguished_name]\n[ v3_req ]\nbasicConstraints = CA:FALSE\nkeyUsage = nonRepudiation, digitalSignature, keyEncipherment\nsubjectAltName = @alt_names\n[alt_names]\nDNS.1 = $(echo -n \"$my_hostname\" | sed s/-[0-9]*$//)\nDNS.2 = $my_hostname\nDNS.3 = $service_name\nDNS.4 = localhost\nDNS.5 = 127.0.0.1\nEOL\n\n    # Generate the certs\n    openssl genrsa -out mongo.key 2048\n    openssl req -new -key mongo.key -out mongo.csr -subj \"/OU=MongoDB/CN=$my_hostname\" -config openssl.cnf\n    openssl x509 -req -in mongo.csr \\\n        -CA \"$ca_crt\" -CAkey \"$ca_key\" -CAcreateserial \\\n        -out mongo.crt -days 3650 -extensions v3_req -extfile openssl.cnf\n\n    rm mongo.csr\n    cat mongo.crt mongo.key > $pem\n    rm mongo.key mongo.crt\nfi\n\ninit_mongod_standalone\n\nlog \"Peers: $${peers[*]}\"\nlog \"Starting a MongoDB replica\"\nmongod --config /data/configdb/mongod.conf --dbpath=/data/db --replSet=\"$replica_set\" --port=\"$${port}\" \"$${auth_args[@]}\" --bind_ip=0.0.0.0 2>&1 | tee -a /work-dir/log.txt 1>&2 &\npid=$!\ntrap shutdown_mongo EXIT\n\nlog \"Waiting for MongoDB to be ready...\"\nretry_until \"localhost\" \"db.adminCommand('ping').ok\" \"1\"\nlog \"Initialized.\"\n\n# try to find a master\nfor peer in \"$${peers[@]}\"; do\n    log \"Checking if $${peer} is primary\"\n    # Check rs.status() first since it could be in primary catch up mode which db.isMaster() doesn't show\n    if [[ $(mongo admin --host \"$${peer}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --quiet --eval \"rs.status().myState\") == \"1\" ]]; then\n        retry_until \"$${peer}\" \"db.isMaster().ismaster\" \"true\"\n        log \"Found primary: $${peer}\"\n        primary=\"$${peer}\"\n        break\n    fi\ndone\n\nif [[ \"$${primary}\" = \"$${service_name}\" ]]; then\n    log \"This replica is already PRIMARY\"\nelif [[ -n \"$${primary}\" ]]; then\n    if [[ $(mongo admin --host \"$${primary}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --quiet --eval \"rs.conf().members.findIndex(m => m.host == '$${service_name}:$${port}')\") == \"-1\" ]]; then\n      log \"Adding myself ($${service_name}) to replica set...\"\n      if (mongo admin --host \"$${primary}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --eval \"rs.add('$${service_name}')\" | grep 'Quorum check failed'); then\n          log 'Quorum check failed, unable to join replicaset. Exiting prematurely.'\n          exit 1\n      fi\n    fi\n\n    sleep 3\n    log 'Waiting for replica to reach SECONDARY state...'\n    retry_until \"$${service_name}\" \"rs.status().myState\" \"2\"\n    log '✓ Replica reached SECONDARY state.'\n\nelif (mongo \"$${ssl_args[@]}\" --eval \"rs.status()\" | grep \"no replset config has been received\"); then\n    log \"Initiating a new replica set with myself ($service_name)...\"\n    mongo \"$${ssl_args[@]}\" --eval \"rs.initiate({'_id': '$replica_set', 'members': [{'_id': 0, 'host': '$service_name'}]})\"\n\n    sleep 3\n    log 'Waiting for replica to reach PRIMARY state...'\n    retry_until \"localhost\" \"db.isMaster().ismaster\" \"true\"\n    primary=\"$${service_name}\"\n    log '✓ Replica reached PRIMARY state.'\n\n    if [[ \"$${AUTH}\" == \"true\" ]]; then\n        log \"Creating admin user...\"\n        mongo admin \"$${ssl_args[@]}\" --eval \"db.createUser({user: '$${admin_user}', pwd: '$${admin_password}', roles: [{role: 'root', db: 'admin'}]})\"\n    fi\nfi\n\n# User creation\nif [[ -n \"$${primary}\" && \"$AUTH\" == \"true\" && \"$METRICS\" == \"true\" ]]; then\n    metric_user_count=$(mongo admin --host \"$${primary}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --eval \"db.system.users.find({user: '$${metrics_user}'}).count()\" --quiet)\n    if [[ \"$${metric_user_count}\" == \"0\" ]]; then\n        log \"Creating clusterMonitor user...\"\n        mongo admin --host \"$${primary}\" \"$${admin_creds[@]}\" \"$${ssl_args[@]}\" --eval \"db.createUser({user: '$${metrics_user}', pwd: '$${metrics_password}', roles: [{role: 'clusterMonitor', db: 'admin'}, {role: 'read', db: 'local'}]})\"\n    fi\nfi\n\nlog \"MongoDB bootstrap complete\"\nexit 0\n"
  }
}

resource "kubernetes_config_map" "mongodb_replicaset_mongodb" {
  metadata {
    name      = "${var.name}-mongodb-replicaset-mongodb"
    namespace = var.namespace

    labels = {
      app     = "mongodb-replicaset"
      release = var.name
    }
  }

  data = {
    "mongod.conf" = "{}\n"
  }
}

resource "kubernetes_service" "mongodb_replicaset" {
  metadata {
    name      = "${var.name}-mongodb-replicaset"
    namespace = var.namespace

    labels = {
      app     = "mongodb-replicaset"
      release = var.name
    }

    annotations = {
      "service.alpha.kubernetes.io/tolerate-unready-endpoints" = "true"
    }
  }

  spec {
    port {
      name = "mongodb"
      port = 27017
    }

    selector = {
      app     = "mongodb-replicaset"
      release = var.name
    }

    cluster_ip                  = "None"
    type                        = "ClusterIP"
    publish_not_ready_addresses = true
  }
}

resource "kubernetes_stateful_set" "mongodb_replicaset" {
  metadata {
    name      = "${var.name}-mongodb-replicaset"
    namespace = var.namespace

    labels = {
      app     = "mongodb-replicaset"
      release = var.name
    }
  }

  spec {
    replicas = var.replicacount

    selector {
      match_labels = {
        app     = "mongodb-replicaset"
        release = var.name
      }
    }

    template {
      metadata {
        labels = {
          app = "mongodb-replicaset"

          release = var.name
        }

        annotations = {
          "checksum/config" = "d2443db7eccf79039fa12519adbce04b24232c89bff87ff7dada29bd0fdd3f48"
        }
      }

      spec {
        volume {
          name = "config"

          config_map {
            name = "${var.name}-mongodb-replicaset-mongodb"
          }
        }

        volume {
          name = "init"

          config_map {
            name         = "${var.name}-mongodb-replicaset-init"
            default_mode = "0755"
          }
        }

        volume {
          name = "workdir"
        }

        volume {
          name = "configdir"
        }

        init_container {
          name    = "copy-config"
          image   = "busybox:1.29.3"
          command = ["sh"]
          args    = ["-c", "set -e\nset -x\n\ncp /configdb-readonly/mongod.conf /data/configdb/mongod.conf\n"]

          volume_mount {
            name       = "workdir"
            mount_path = "/work-dir"
          }

          volume_mount {
            name       = "config"
            mount_path = "/configdb-readonly"
          }

          volume_mount {
            name       = "configdir"
            mount_path = "/data/configdb"
          }

          image_pull_policy = "IfNotPresent"
        }

        init_container {
          name  = "install"
          image = "unguiculus/mongodb-install:0.7"
          args  = ["--work-dir=/work-dir"]

          volume_mount {
            name       = "workdir"
            mount_path = "/work-dir"
          }

          image_pull_policy = "IfNotPresent"
        }

        init_container {
          name    = "bootstrap"
          image   = "mongo:bionic"
          command = ["/work-dir/peer-finder"]
          args    = ["-on-start=/init/on-start.sh", "-service=$(POD_NAME)-mongodb-replicaset"]

          env {
            name  = "POD_NAME"
            value = var.name
          }

          env {
            name = "POD_NAMESPACE"

            value_from {
              field_ref {
                api_version = "v1"
                field_path  = "metadata.namespace"
              }
            }
          }

          env {
            name  = "REPLICA_SET"
            value = "rs0"
          }

          env {
            name  = "TIMEOUT"
            value = "900"
          }

          volume_mount {
            name       = "workdir"
            mount_path = "/work-dir"
          }

          volume_mount {
            name       = "init"
            mount_path = "/init"
          }

          volume_mount {
            name       = "configdir"
            mount_path = "/data/configdb"
          }

          volume_mount {
            name       = "datadir"
            mount_path = "/data/db"
          }

          image_pull_policy = "IfNotPresent"
        }

        container {
          name    = "mongodb-replicaset"
          image   = "mongo:bionic"
          command = ["mongod"]
          args    = ["--config=/data/configdb/mongod.conf", "--dbpath=/data/db", "--replSet=rs0", "--port=27017", "--bind_ip=0.0.0.0"]

          port {
            name           = "mongodb"
            container_port = 27017
          }

          volume_mount {
            name       = "datadir"
            mount_path = "/data/db"
          }

          volume_mount {
            name       = "configdir"
            mount_path = "/data/configdb"
          }

          volume_mount {
            name       = "workdir"
            mount_path = "/work-dir"
          }

          resources {
            limits     = {
              cpu    = var.limit_cpu
              memory = var.limit_mem
            }

            requests = {
              cpu    = var.request_cpu
              memory = var.request_mem
            }
          }

          liveness_probe {
            exec {
              command = ["mongo", "--eval", "db.adminCommand('ping')"]
            }

            initial_delay_seconds = 30
            timeout_seconds       = 5
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          readiness_probe {
            exec {
              command = ["mongo", "--eval", "db.adminCommand('ping')"]
            }

            initial_delay_seconds = 5
            timeout_seconds       = 1
            period_seconds        = 10
            success_threshold     = 1
            failure_threshold     = 3
          }

          image_pull_policy = "IfNotPresent"
        }

        termination_grace_period_seconds = 30

        security_context {
          run_as_user     = 999
          run_as_non_root = true
          fs_group        = 999
        }
      }
    }

    volume_claim_template {
      metadata {
        name = "datadir"
      }

      spec {
        access_modes       = ["ReadWriteOnce"]
        storage_class_name = var.storage_class_name

        resources {
          requests = {
            storage = "${var.storage_size}"
          }
        }
      }
    }

    service_name = "${var.name}-mongodb-replicaset"
  }
}
