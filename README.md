# Clickhouse-copier in a docker container

## Installation

Use docker-compose and create some ENV vars to magane the copier parameters.  In version 22+ positional argument names have been changed so to avoid debugging issues chck the new parameter names by:

```bash
$ clickhouse-copier --help
usage: clickhouse-copier --config-file <config-file> --task-path <task-path>
Copies tables from one cluster to another

-C<file>, --config-file=<file>                                                         load configuration from a given file
-L<file>, --log-file=<file>                                                            use given log file
-E<file>, --errorlog-file=<file>                                                       use given log file for errors only
-P<file>, --pid-file=<file>                                                            use given pidfile
--daemon                                                                               Run application as a daemon.
--umask=mask                                                                           Set the daemon's umask (octal, e.g. 027).
--pidfile=path                                                                         Write the process ID of the application to given file.
--task-path=task-path                                                                  path to task in ZooKeeper
--task-file=task-file                                                                  path to task file for uploading in ZooKeeper to task-path
--task-upload-force=task-upload-force                                                  Force upload task-file even node already exists
--safe-mode                                                                            disables ALTER DROP PARTITION in case of errors
--copy-fault-probability=copy-fault-probability                                        the copying fails with specified probability (used to test partition state recovering)
--move-fault-probability=move-fault-probability                                        the moving fails with specified probability (used to test partition state recovering)
--log-level=log-level                                                                  sets log level
--base-dir=base-dir                                                                    base directory for copiers, consecutive copier launches will populate
                                                                                       /base-dir/launch_id/* directories
--experimental-use-sample-offset=experimental-use-sample-offset                        Use SAMPLE OFFSET query instead of cityHash64(PRIMARY KEY) % n == k
--status                                                                               Get for status for current execution
--max-table-tries=max-table-tries                                                      Number of tries for the copy table task
--max-shard-partition-tries=max-shard-partition-tries                                  Number of tries for the copy one partition task
--max-shard-partition-piece-tries-for-alter=max-shard-partition-piece-tries-for-alter  Number of tries for final ALTER ATTACH to destination table
--retry-delay-ms=retry-delay-ms                                                        Delay between task retries
--help
```

In docker mode do not use the ```--daemon```  it will generate an error and the container will not launch. Check the following ```docker-compose.yaml```
to see which params are used.

```yaml
---
version: "3"

services:
  clickhouse_copier:
    container_name: clickhouse_copier
    image: clickhouse/clickhouse-server:21.8
    volumes:
      - ./configs:/var/lib/clickhouse/tmp
    command:
      - clickhouse-copier
      - "--config-file=${CH_COPIER_CONFIG}"
      - "--task-path=${CH_COPIER_TASKPATH}"
      - "--task-file=${CH_COPIER_TASKFILE}"
      - "--base-dir=${CH_COPIER_BASEDIR}"
    networks:
      - altinity_default

networks:
  altinity_default:
    external: true
```

Also recommended to use the same docker network for zookeeper, clickhouse-server and clickhouse-copier.
