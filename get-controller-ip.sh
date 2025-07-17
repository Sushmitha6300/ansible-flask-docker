#!/bin/bash

# Navigate to the terraform directory
cd terraform

# Save controller IP from terraform output to a file in the root directory
terraform output -raw controller_public_ip > ../controller-ip.txt
