# CTFd AWS Terraform module

![ci workflow](https://github.com/1nval1dctf/terraform-aws-ctfd/actions/workflows/ci.yml/badge.svg)
Terraform module to deploy [CTFd](https://ctfd.io/) into scalable AWS infrastructure

This has been used in a moderately sized CTF > 1000 participants and performed well with a setup similar to the example below, though you may want to scale out a little.

## Design

The CTFd setup Looks something like this:

```mermaid
flowchart TB

  subgraph "Uploads"
    S3Uploads[S3]
  end

  subgraph "Logs"
    S3Logs[S3]
  end

  subgraph "RDS (mysql -  Serverless or Provisioned)"
    RDS[RDS autoscale]
  end

  subgraph "ElasticCache (redis)"
    REDIS[REDIS] --> ElasticCache1[Instance 1]
    REDIS[REDIS] --> ElasticCache[...]
    REDIS[REDIS] --> ElasticCacheN[Instance n]
  end

  LB[ALB] --> Ingress

  subgraph ECS[ECS]
    Ingress --> Service[CTFd service]
    Service --> Instance1[CTFd Instance 1]
    Service --> Instance[CTFd Instance ...]
    Service --> InstanceN[CTFd Instance n - HorizontalAutoScaling]
    Instance1 --> RDS[RDS]
    Instance --> RDS
    InstanceN --> RDS
    Instance1 --> REDIS[REDIS]
    Instance --> REDIS
    InstanceN --> REDIS
    Instance1 --> S3Uploads
    Instance --> S3Uploads
    InstanceN --> S3Uploads
    end
  ECS --> S3Logs
```
