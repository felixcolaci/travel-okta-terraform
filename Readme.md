# Let's Travel Okta Terraform

This repo contains the okta configuration needed to conduct the [Let's Travel Okta](https://github.com/tohcnam/letsTravel-okta) demo.

# Try Out

Prerequsities

- New Okta tenant with OIE enabled
- Github Account and Github Personal Access Token (PAT) at hands --> needs permissions to manage repositories
- Heroku Account and API Key for it ready
- Terraform installed locally

```sh

# install dependencies
$ terraform init

# create a config file
$ cp config/example.tfvars.sample config/my-demo.tfvars
$ vi config/my-demo.tfvars

# apply configuration
$ terraform apply -var-file=config/my-demo.tfvars


```
