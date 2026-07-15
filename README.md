# AWS Disaster Recovery (DR) Simulation – RDS Multi‑AZ Failover & RTO Measurement

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![AWS CLI](https://img.shields.io/badge/AWS%20CLI-2.x-blue)](https://aws.amazon.com/cli/)
[![Bash](https://img.shields.io/badge/Bash-4.4+-green)](https://www.gnu.org/software/bash/)

A production‑ready Bash toolkit to **simulate an Availability Zone (AZ) failure** in AWS and **measure the Recovery Time Objective (RTO)** of your application stack. The scripts force an RDS Multi‑AZ failover, terminate ECS tasks running in the affected AZ, and automatically calculate the time until your service becomes healthy again.

---

## 📖 Table of Contents

- [Overview](#overview)
- [How It Works](#how-it-works)
- [Prerequisites](#prerequisites)
- [Scripts](#scripts)
  - [1. `simulate-az-failure.sh`](#1-simulate-az-failuresh)
  - [2. `measure-rto.sh`](#2-measure-rtosh)
- [Getting Started](#getting-started)
- [Step‑by‑Step Simulation Run](#stepbystep-simulation-run)
- [Understanding the RTO Output](#understanding-the-rto-output)
- [IAM Permissions](#iam-permissions)
- [Customization](#customization)
- [Limitations & Considerations](#limitations--considerations)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

In a cloud‑native architecture, **Multi‑AZ deployments** are the cornerstone of high availability. When an AZ fails, your database (RDS) automatically fails over to a standby replica in another AZ, and your application containers (ECS) should be rescheduled in surviving AZs.

These scripts help you:
- **Proactively test** your failover mechanisms without manual intervention.
- **Quantify** the actual downtime (RTO) experienced by your users.
- **Validate** that your application health checks, load balancers, and service discovery work as expected during an outage.

The tools are deliberately **minimal and transparent** – they use only the AWS CLI and `curl`, so you can easily adapt them to your own environment.

---

## How It Works

```mermaid
sequenceDiagram
    participant User
    participant simulate-az-failure
    participant measure-rto
    participant AWS

    User->>measure-rto: Start monitoring (Phase 1)
    measure-rto->>AWS: Poll ALB /health every 5s
    User->>simulate-az-failure: Run failure simulation
    simulate-az-failure->>AWS: Describe RDS (check Multi‑AZ)
    simulate-az-failure->>AWS: Describe ECS tasks in primary AZ
    simulate-az-failure->>AWS: Reboot RDS with --force-failover
    AWS-->>simulate-az-failure: Failover starts
    simulate-az-failure-->>simulate-az-failure: Poll RDS until status=available & AZ changed
    simulate-az-failure->>AWS: Stop ECS task in old AZ
    AWS-->>measure-rto: Health endpoint becomes 5xx/unreachable
    measure-rto-->>measure-rto: Record failure timestamp (T1)
    loop Until health returns 200
        measure-rto->>AWS: Poll ALB /health
    end
    measure-rto-->>measure-rto: Record recovery timestamp (T2)
    measure-rto->>User: Display RTO = T2 - T1