output "travel_app_client_id" {
  value = okta_app_oauth.travel_website.client_id

}

output "travel_app_client_secret" {
  sensitive = true
  value     = okta_app_oauth.travel_website.client_secret
}

output "auth_server" {
  value = data.okta_auth_server.default.issuer
}
