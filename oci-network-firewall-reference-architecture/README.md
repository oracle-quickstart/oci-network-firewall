# OCI Network Firewall - Reference Architecture

We are using combined architecture where we are using dynamic routing gateway with OCI Network Firewall running in Firewall VCN (Hub VCN). This architecture has a central component (the hub) that's connected to multiple networks around it, like a spoke. 

**Note**: You can deploy OCI Network Firewall in Distributed and/or Transit Architecture. To learn more about architecture check the official Reference Architecture docs [here](https://docs.oracle.com/en/solutions/oci-network-firewall). Deployment of **OCI Network Firewall** takes some time so consider that.

## Architecture Diagram

![](./images/archs.png)

## Prerequisites

You should complete below pre-requisites before proceeding to next section:
- You have an active Oracle Cloud Infrastructure Account.
  - Tenancy OCID, User OCID, Compartment OCID, Private and Public Keys are setup properly.
- Permission to `manage` the following types of resources in your Oracle Cloud Infrastructure tenancy: `vcns`, `internet-gateways`, `route-tables`, `security-lists`,`dynamic-routing-gateways`, `subnets` and `instances`.
- Quota to create the following resources: 2 VCNS, 5 subnets, and 4 compute instance as per architecture topology.

If you don't have the required permissions and quota, contact your tenancy administrator. See [Policy Reference](https://docs.cloud.oracle.com/en-us/iaas/Content/Identity/Reference/policyreference.htm), [Service Limits](https://docs.cloud.oracle.com/en-us/iaas/Content/General/Concepts/servicelimits.htm), [Compartment Quotas](https://docs.cloud.oracle.com/iaas/Content/General/Concepts/resourcequotas.htm).

## Deployment Options

You can deploy this architecture using two approaches explained in each section: 
1. Using Oracle Resource Manager 
2. Using Terraform CLI 

## Deploy Using Oracle Resource Manager

In this section you will follow each steps given below to create this architecture:

1. **Click** [![Deploy to Oracle Cloud](https://oci-resourcemanager-plugin.plugins.oci.oraclecloud.com/latest/deploy-to-oracle-cloud.svg)](https://console.us-phoenix-1.oraclecloud.com/resourcemanager/stacks/create?region=home&zipUrl=https://github.com/oracle-quickstart/oci-network-firewall/raw/master/oci-network-firewall-reference-architecture/resource-manager/oci-network-firewall.zip)

    > If you aren't already signed in, when prompted, enter the tenancy and user credentials.

2. Review and accept the terms and conditions.

3. Select the region where you want to deploy the stack.

4. Follow the on-screen prompts and instructions to create the stack.

5. After creating the stack, click **Terraform Actions**, and select **Plan** from the stack on OCI console UI.

6. Wait for the job to be completed and review the plan.

    > To make any changes, return to the Stack Details page, click **Edit Stack**, and make the required changes. Then, run the **Plan** action again.

7. If no further changes are necessary, return to the Stack Details page, click **Terraform Actions**, and select **Apply**. 

8. At this stage your architecture should have been deployed successfully. You can proceed to next section for configuring your OCI Network Firewall.

9. If you no longer require your infrastructure, return to the Stack Details page and **Terraform Actions**, and select **Destroy**.

## Deploy Using the Terraform CLI

In this section you will use **Terraform** locally to create this architecture: 

1. Create a local copy of this repo using below command on your terminal: 

    ```
    git clone https://github.com/oracle-quickstart/oci-network-firewall.git
    cd oci-network-firewall-reference-architecture/
    ls
    ```

2. Complete the prerequisites described [here] which are associated to install **Terraform** [locally](https://github.com/oracle-quickstart/oci-prerequisites#install-terraform).
    Make sure you have terraform v0.13+ cli installed and accessible from your terminal.

    ```bash
    terraform -v

    Terraform v0.13.0
    + provider.oci v4.85.0
    ```

3. Create a `terraform.tfvars` file in your **oci-network-firewall-reference-architecture** directory, and specify the following variables:

    ```
    # Authentication
    tenancy_ocid         = "<tenancy_ocid>"
    user_ocid            = "<user_ocid>"
    fingerprint          = "<finger_print>"
    private_key_path     = "<pem_private_key_pem_file_path>"

    # SSH Keys
    ssh_public_key  = "<public_ssh_key_string_value>"

    # Region
    region = "<oci_region>"

    # Compartment
    compute_compartment_ocid = "<compartment_ocid>"
    network_compartment_ocid = "<network_compartment_ocid>"
    availability_domain_number = "<availability_domain_number>

    ````

4. Create the Resources using the following commands:

    ```bash
    terraform init
    terraform plan
    terraform apply
    ```

5. At this stage your architecture should have been deployed successfully. You can proceed to next section for configuring your **OCI Network Firewall**. 

6. If you no longer require your infrastructure, you can run this command to destroy the resources:

    ```bash
    terraform destroy
    ```

## Configuration

You can follow the official page to know more about [OCI Network Firewall and Configuration](https://docs.oracle.com/en-us/iaas/Content/network-firewall/overview.htm). 

**Note:** You can enhance this automation to meet your use-case requirements. We have created a new environment to validate this architecture and automation. Check out OCI Terraform [Examples here](https://registry.terraform.io/providers/oracle/oci/latest/docs/resources/network_firewall_network_firewall#example-usage).

## Feedback 

Feedbacks are welcome to this repo, please open a PR if you have any.
