# Clickhouse-copier deployment in altinity.cloud

Create a couple of cluster in the altinity.cloud platform and deploy Clickhouse-copier. It will copy data from one cluster to another.
Some documentation to read:
* https://kb.altinity.com/altinity-kb-setup-and-maintenance/altinity-kb-data-migration/altinity-kb-clickhouse-copier/
* https://clickhouse.com/docs/en/operations/utilities/clickhouse-copier/


## Manual deployment

Inside the kubernetes folder there are some manifests to create a deployment of the copier. This method is good for testing purposes
and also if you want to have direct control of the deployment steps. It would be necessary to edit/change all the ```yaml``` files to your needs.

### 1) Create the PVC:

First create a namespace in which all the pods and resources are going to be deployed

```bash
kubectl create namespace clickhouse-copier
```

Then create the PVC using a ```storageClass``` gp2-encrypted class.

```bash
kubectl create -f ./kubernetes/copier-pvc.yaml
```

### 2) Create the configmap:

The configmap has both files ```zookeeper.xml``` and ```task01.xml``` with the zookeeper node listing and the parameters for the task respectively.

```bash
kubectl create -f ./kubernetes/copier-configmap.yaml
```

The ```task01.xml``` file has many parameters to take into account explained in the [clickhouse-copier documentation](https://clickhouse.com/docs/en/operations/utilities/clickhouse-copier/). Important to note that it is needed a FQDN for the zookeeper nodes and clickhouse server that are valid for the cluster. As the deployment creates a new namespace, it is recommended to use a FQDN linked to a service. For example ```zookeeper-20705.eu.svc.cluster.local```. This file should be adapted to both clusters topologies and to the needs of the user.

The ```zookeeper.xml``` file is pretty straightforward with a simple 3 node ensemble configuration.


### 3) Create the job:

Basically the job will download the official clickhouse image and will create a pod with 2 containers:
  * clickhouse-copier: This container will run the clickhouse-copier utility.
  * sidecar-logging: This container will be used to read the logs of the clickhouse-copier container because clickhouse-copier does not send the logs to ```stdout/stderr```. Also using ```---daemon``` is not sending the logs to ```stdout/stderr``` either.

To check for the logs simply:

```bash
kubectl -n clickhouse-copier logs <podname> sidecar-logging
```

## Terraform deployment

Just review the terraform directory and execute ```terraform init``` and ```terraform plan``` to check. After review the plan, execute ```terraform apply``` to deploy the copier.
