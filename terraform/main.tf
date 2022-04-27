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


resource "kubernetes_deployment" "clickhouse-copier" {
  metadata {
    name      = "clickhouse-copier"
    namespace = var.namespace_job
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        app   = "clickhouse-copier"
        front = "apps"
      }
    }
    template {
      metadata {
        labels = {
          app   = "clickhouse-copier"
          front = "apps"
        }
      }
      spec {
        node_name = "kube-master"
        container {
          image = "nginx"
          name  = "clickhouse-copier"
          port {
            container_port = 80
          }
          volume_mount {
            mount_path = "/usr/share/nginx/html"
            name       = "clickhouse-copier"
          }
        }
        volume {
          name = "clickhouse-copier"
          persistent_volume_claim {
            claim_name = "clickhouse-copier"
          }
        }
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "clickhouse-copier" {
  metadata {
    name = "clickhouse-copier"
    labels = {
      app   = "clickhouse-copier"
      front = "apps"
    }
  }
  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "clickhouse-copier"
    resources {
      requests = {
        storage = "2Gi"
      }
    }
  }
}

resource "kubernetes_persistent_volume" "clickhouse-copier" {
  metadata {
    name = "clickhouse-copier"
    labels = {
      app   = "clickhouse-copier"
      front = "apps"
    }
  }
  spec {
    capacity = {
      storage = "2Gi"
    }
    access_modes                     = ["ReadWriteOnce"]
    storage_class_name               = "clickhouse-copier"
    persistent_volume_reclaim_policy = "Retain"
    node_affinity {
      required {
        node_selector_term {
          match_expressions {
            key      = "kubernetes.io/hostname"
            operator = "In"
            values   = ["kube-master"]
          }
        }
      }
    }
    persistent_volume_source {
      local {
        path = "/home/dnieto"
      }
    }
  }
}

resource "kubernetes_service" "clickhouse-copier" {
  metadata {
    name      = "clickhouse-copier"
    namespace = var.namespace_job
  }
  spec {
    selector = {
      app = kubernetes_deployment.clickhouse-copier.spec.0.template.0.metadata.0.labels.app
    }
    type = "LoadBalancer"
    port {
      port        = 7070
      target_port = 80
    }
  }
}
