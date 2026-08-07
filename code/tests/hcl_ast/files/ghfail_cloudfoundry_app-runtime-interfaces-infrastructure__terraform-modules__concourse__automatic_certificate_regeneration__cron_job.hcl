resource "kubernetes_cron_job_v1" "automatic_certificate_regeneration" {
  metadata {
    name = "certificate-regeneration"
    namespace = "concourse"
  }
  spec {
    schedule                      = "@monthly"
    failed_jobs_history_limit     = 2
    successful_jobs_history_limit = 2
    job_template {
      metadata {}
      spec {
        template {
          metadata {}
          spec {
            restart_policy = "OnFailure"
            container {
              name              = "cert-regen"
              image             = "cloudfoundry/cf-deployment-concourse-tasks:v20.7.0"
              image_pull_policy = "IfNotPresent"
              command           = ["bash", "-c", "IFS=',' read -r -a CERTIFICATES <<< \"$CERTS_TO_RENEW\"; for cert in \"$${CERTIFICATES[@]}\"; do credhub regenerate -n \"$cert\"; done"]
              env {
                name  = "CERTS_TO_RENEW"
                value = var.certificates_to_regenerate
              }
              env {
                name  = "CREDHUB_SERVER"
                value = "https://credhub.concourse.svc.cluster.local:9000"
              }
              env {
                name = "CREDHUB_CA_CERT"
                value_from {
                  secret_key_ref {
                    key  = "certificate"
                    name = "credhub-root-ca"
                  }
                }
              }
              env {
                name  = "CREDHUB_CLIENT"
                value = "credhub_admin_client"
              }
              env {
                name = "CREDHUB_SECRET"
                value_from {
                  secret_key_ref {
                    key  = "password"
                    name = "credhub-admin-client-credentials"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
