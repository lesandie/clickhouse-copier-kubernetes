variable "namespace_job" {
  description = "Namespace for the job"
  default = "clickhouse-copier"
}

variable "base_dir_job" {
  description = "Basedir parameter for clickhouse-copier"
  default = "/var/lib/clickhouse/tmp"
}

variable "config_file_job" {
  description = "Config map config file for clickhouse-copier"
  default = "/var/lib/clickhouse/tmp/zookeeper.xml"
}

variable "task_file_job" {
  description = "Config map task file for clickhouse-copier"
  default = "/var/lib/clickhouse/tmp/task01.xml"
}

variable "task_path_job" {
  description = "Task pzookeeper path from clickhouse-copier"
  default = "/clickhouse/copier/tasks/task01"
}

# Also can be used: export TF_VAR_namespace_job="clickhouse-copier"
# variable "namespace_job" {
#   description = "Namespace for the job"
#   type = "string"
#
#   and assign it like var.namespace_job
