terraform {
  required_providers {
    heroku = {
      source  = "heroku/heroku"
      version = "5.1.0"
    }
  }
}

provider "heroku" {
  email   = var.heroku_email
  api_key = var.heroku_api_key
}

resource "heroku_app" "demo_app" {
  name       = var.demo_name
  region     = var.heroku_region
  stack      = "container"
  buildpacks = ["heroku/nodejs"]
  config_vars = {
    PORT                = 3000
    ISSUER              = "${var.issuer}/oauth2/default"
    ISSUER_BASE         = var.issuer
    CLIENT_ID           = var.client_id
    CLIENT_SECRET       = var.client_secret
    CUSTOM_LOGIN        = false
    REDIRECT_URI        = "https://${var.demo_name}.herokuapp.com/authorization-code/callback"
    APPBASEURL          = "https://${var.demo_name}.herokuapp.com"
    SCOPE               = "openid profile email read:demo offline_access"
    CUSTOM_REGISTRATION = false
    ADMINTOKEN          = var.okta_admin_token
  }
}

