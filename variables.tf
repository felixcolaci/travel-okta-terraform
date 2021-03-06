
// required variables to set
variable "okta_org" {
  type = string
}

variable "okta_admintoken" {
  type = string
}

variable "idp_social_facebook_client_id" {
  type = string
}
variable "idp_social_facebook_client_secret" {
  type = string
}
variable "idp_social_google_client_id" {
  type = string
}
variable "idp_social_google_client_secret" {
  type = string
}
// optional variables
variable "okta_environment" {
  type    = string
  default = "oktapreview.com"
}

variable "travel_app_redirect_uris" {
  type    = list(string)
  default = ["http://localhost:3000/authorization-code/callback"]
}

variable "travel_app_post_logout_redirect_uris" {
  type    = list(string)
  default = ["http://localhost:3000"]
}

variable "github_token" {
  type = string
}

variable "demo_name" {
  type = string
}

variable "heroku_api_key" {
  type = string
}
variable "heroku_email" {
  type = string
}

variable "okta_issuer_url" {
  type = string
}
