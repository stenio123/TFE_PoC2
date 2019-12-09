# Sentinel Policies

Sentinel is used to enforce governance and best practice in deployments.

Example policies can be found here:

https://github.com/hashicorp/terraform-guides/tree/master/governance/second-generation

For using Sentinel:
- Each policy is defined as an individual *.sentinel file
- A sentinel repository needs to have a sentinel.hcl file defining enforcement levels for each policy (advisory, soft-mandatory, hard-mandatory)
- The sentinel repository can be independent, or with a folder of another repository

Additional information: https://www.terraform.io/docs/cloud/sentinel/