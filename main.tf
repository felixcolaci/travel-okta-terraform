module "okta" {
  source = "./okta"
  # conf
  okta_org                             = var.okta_org
  okta_admintoken                      = var.okta_admintoken
  idp_social_facebook_client_id        = var.idp_social_facebook_client_id
  idp_social_facebook_client_secret    = var.idp_social_facebook_client_secret
  idp_social_google_client_id          = var.idp_social_google_client_id
  idp_social_google_client_secret      = var.idp_social_google_client_secret
  okta_environment                     = var.okta_environment
  travel_app_redirect_uris             = var.travel_app_redirect_uris
  travel_app_post_logout_redirect_uris = var.travel_app_post_logout_redirect_uris
  demo_name                            = var.demo_name
}

module "github" {
  source = "./github"
  # conf
  github_token   = var.github_token
  demo_name      = var.demo_name
  heroku_api_key = var.heroku_api_key
  heroku_email   = var.heroku_email
}

module "heroku" {
  source = "./heroku"

  # conf
  heroku_api_key = var.heroku_api_key
  heroku_email   = var.heroku_email
  demo_name      = var.demo_name
  issuer         = var.okta_issuer_url
  # dependencies
  demo_clone_url = module.github.clone_url
  client_id      = module.okta.travel_app_client_id
  client_secret  = module.okta.travel_app_client_secret
}
