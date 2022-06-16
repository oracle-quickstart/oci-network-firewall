# oci-network-firewall

This is a Terraform module that deploys OCI Network Firewall solutions on [Oracle Cloud Infrastructure (OCI)](https://docs.oracle.com/iaas/Content/network-firewall/overview.htm). It is developed jointly by Oracle and Palo Alto Networks.

The [Oracle Cloud Infrastructure (OCI) Quick Start](https://github.com/oracle?q=quickstart) is a collection of examples that allow OCI users to get a quick start deploying advanced infrastructure on OCI. The **oci-network-firewall** repository contains the initial templates that can be used for accelerating deployment of OCI Network Firewall Solution and related configuration from local Terraform CLI and OCI Resource Manager.

This repo is under active development. Building open source software is a community effort. We're excited to engage with the community building this.

## How this project is organized

This project contains multiple solutions. Each solution folder is structured in at least 3 modules:

- **solution-folder**: launch a simple VM that subscribes to a Marketplace Image running from Terraform CLI.
- **solution-folder/build-orm**: Package cloudguard-ngfw template in OCI [Resource Manager Stack](https://docs.cloud.oracle.com/iaas/Content/ResourceManager/Tasks/managingstacksandjobs.htm) format.
- **solution-folder/terraform-modules**: Contains a list of re-usable terraform modules (if any) for managing infrastructure resources like vcn, subnets, security, etc.

## Current Solutions 

This project includes below solutions supported: 

- **OCI Network Firewall Reference Architecture** : [oci-network-firewall-reference-architecture](oci-network-firewall-reference-architecture) this allows end user to deploy OCI Network Firewall in a distributed architecture. It uses Dynamic Routing Gateway to communicate between VCNs and from/to VCNs. 
- **Create Certificate Scripts** : [create-certificate](scripts) this allows end user to create certificate using shell script. Which can be used to create decryption profiles on OCI Network Firewall Policy.

## How to use these templates

To get it started, navigate to the solution folder and check individual README.md file. 
