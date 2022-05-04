terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.10.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config.altinity"
}

resource "kubernetes_namespace" "clickhouse_copier" {
  metadata {
    name = var.namespace_job
  }
}

resource "kubernetes_job" "clickhouse_copier_job" {
  metadata {
    name = "clickhouse-copier"
    namespace = var.namespace_job
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "clickhouse-copier"
          image   = "clickhouse/clickhouse-server:21.8"
          command = [
            "clickhouse-copier", "--config-file=${var.config_file_path}",
            "--task-file=${var.task_file_path}", "--task-path=${var.task_path}",
            "--base-dir=${var.base_dir_path}", "--task-upload-force=1",
          ]
          volume_mount {
            mount_path = var.base_dir_path
            name = "copier-logs"
          }
          volume_mount {
            mount_path = var.config_file_path
            sub_path = var.config_file
            name = "copier-config"
          }
          volume_mount {
            mount_path = var.task_file_path
            sub_path = var.task_file
            name = "copier-config"
          }
        }
        container {
          name    = "sidecar-logger"
          image   = "busybox:1.35"
          command = ["/bin/sh", "-c", "tail -n 1000 -f /tmp/copier-logs/clickhouse-copier*/*.log"]
          volume_mount {
            mount_path = "/tmp/copier-logs"
            name = "copier-logs"
          }
        }
        volume {
          name = "copier-config"
          config_map {
            name = "copier-config"
            optional = true # <= rejected.
          }
        }
        volume {
          name = "copier-logs"
          persistent_volume_claim {
            claim_name = "copier-logs"
          }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
  }
  wait_for_completion = true
  timeouts {
    create = "20m"
    update = "2m"
  }
}

resource "kubernetes_config_map" "copier_configmap" {
  metadata {
    name = "copier-config"
    namespace = var.namespace_job
  }
  data = {
    "zookeeper.yml" = "${file("${path.module}/configs/zookeeper.xml")}"
    "task01.yml" = "${file("${path.module}/configs/task01.xml")}"
  }
}

resource "kubernetes_persistent_volume_claim" "copier_logs_pvc" {
  metadata {
    name = "copier-logs"
    namespace = var.namespace_job
  }
  spec {
    access_modes = ["ReadWriteMany"]
    storage_class_name = "gp2-encrypted"
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}
