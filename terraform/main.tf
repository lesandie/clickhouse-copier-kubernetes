terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "clickhouse-copier" {
  metadata {
    name = var.namespace_job
  }
}

resource "kubernetes_job" "clickhouse-copier" {
  metadata {
    name = "clickhouse-copier"
    namespace = var.namespace_job
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "clickhouse_copier"
          image   = "clickhouse/clickhouse-server:21.8"
          command = [
            "clickhouse-copier", "--config-file=${var.config_file_job}",
            "--task-file=${var.task_file_job}", "--task-path=${var.task_path_job}",
            "--base-dir=${var.base_dir_job}"
          ]
          volume_mount {
            mount_path = "/var/lib/clickhouse/tmp"
            name = "copier-config"
          }
        }
        volume {
          name = "copier-config"
          config_map {
            name = "copier-config"
            optional = true # <= rejected.
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  timeouts {
    create = "2m"
    update = "2m"
  }
}

resource "kubernetes_config_map" "copier-config" {
  metadata {
    name = "copier-config"
    namespace = var.namespace_job
  }
  data = {
    "zookeeper.yml" = "${file("${path.module}/configs/zookeeper.xml")}"
    "task01.yml" = "${file("${path.module}/configs/task01.xml")}"
  }
}
