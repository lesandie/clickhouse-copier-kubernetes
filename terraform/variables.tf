variable "namespace_job" {
  description = "Namespace for the job"
  type = string
  default = "clickhouse-copier"
}

variable "base_dir_path" {
  description = "Basedir parameter for clickhouse-copier"
  type = string
  default = "/var/lib/clickhouse/tmp"
}

variable "config_file" {
  description = "Config file name for clickhouse-copier"
  type = string
  default = "zookeeper.xml"
}

variable "task_file" {
  description = "Task file name for clickhouse-copier"
  type = string
  default = "task01.xml"
}

variable "task_path" {
  description = "Task zookeeper path for clickhouse-copier"
  type = string
  default = "/clickhouse/copier/tasks/task01"
}

variable "config_file_path" {
  description = "Config file full path for clickhouse-copier"
  type = string
  default = "/var/lib/clickhouse/tmp/zookeeper.xml"
}

variable "task_file_path" {
  description = "Task file full path for clickhouse-copier"
  type = string
  default = "/var/lib/clickhouse/tmp/task01.xml"
}

# Also can be used: export TF_VAR_namespace_job="clickhouse-copier"
# variable "namespace_job" {
#   description = "Namespace for the job"
#   type = "string"
#
#   and assign it like var.namespace_job
