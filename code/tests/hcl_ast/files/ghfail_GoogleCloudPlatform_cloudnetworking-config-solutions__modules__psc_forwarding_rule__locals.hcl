/**
 * Copyright 2024-2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  forwarding_rule_targets = {
    for k, v in var.psc_endpoints :
    k => (v.producer_cloudsql != null && v.producer_cloudsql.instance_name != null) ?
    try(data.google_sql_database_instance.cloudsql_instance[k].psc_service_attachment_link, null) :
    (v.producer_alloydb != null && v.producer_alloydb.instance_name != null && length(try(data.google_alloydb_instance.alloydb_instance[k].psc_instance_config, [])) > 0) ?
    try(data.google_alloydb_instance.alloydb_instance[k].psc_instance_config[0].service_attachment_link, null) :
    v.target
  }
}