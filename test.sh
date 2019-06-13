#!/bin/bash
set -ex
# terraform destroy -auto-approve
terraform apply -auto-approve
terraform taint aws_instance.test
terraform apply -auto-approve -var 'associate=1'
