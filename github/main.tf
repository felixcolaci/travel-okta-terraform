terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 4.0"
    }
  }
}

provider "github" {
  token = var.github_token
}


resource "github_repository" "demo_app" {
  visibility = "private"
  name       = var.demo_name
  template {
    owner      = "felixcolaci"
    repository = "letsTravel-okta"
  }
}


resource "github_actions_secret" "heroku_api_key" {
  repository      = github_repository.demo_app.name
  secret_name     = "HEROKU_API_KEY"
  plaintext_value = var.heroku_api_key
}
resource "github_actions_secret" "heroku_app_name" {
  repository      = github_repository.demo_app.name
  secret_name     = "HEROKU_APP_NAME"
  plaintext_value = var.demo_name
}
resource "github_actions_secret" "heroku_email" {
  repository      = github_repository.demo_app.name
  secret_name     = "HEROKU_EMAIL"
  plaintext_value = var.heroku_email
}
