terraform {
  required_providers {
    okta = {
      source  = "okta/okta"
      version = "~> 3.31"
    }
  }
}

# Configure the Okta Provider
provider "okta" {
  org_name  = var.okta_org
  base_url  = var.okta_environment
  api_token = var.okta_admintoken
}

resource "okta_app_oauth" "travel_website" {
  label       = var.demo_name
  type        = "web"
  grant_types = ["authorization_code"]

  redirect_uris             = concat(var.travel_app_redirect_uris, ["https://${var.demo_name}.herokuapp.com/authorization-code/callback"])
  post_logout_redirect_uris = concat(var.travel_app_post_logout_redirect_uris, ["https://${var.demo_name}.herokuapp.com"])
  response_types            = ["code"]
  implicit_assignment       = true
  authentication_policy     = okta_app_signon_policy.travel_website.id
}


data "okta_group" "everyone" {
  name = "Everyone"
}
// disable in favor of application broker mode `okta_app_oauth.travel_website.implicit_assignment`
// resource "okta_app_group_assignment" "everyone" {
//   app_id   = okta_app_oauth.travel_website.id
//   group_id = data.okta_group.everyone.id
// }

resource "okta_user_schema_property" "auth" {
  index       = "auth"
  title       = "Preferred Authentication mode"
  type        = "string"
  master      = "OKTA"
  permissions = "READ_WRITE"
  enum        = ["password", "mfa", "passwordless-email", "passwordless-biometric", ]
  one_of {
    const = "password"
    title = "Password"
  }
  one_of {
    const = "mfa"
    title = "MFA Opt-In"
  }
  one_of {
    const = "passwordless-email"
    title = "Passwordless Email"
  }
  one_of {
    const = "passwordless-biometric"
    title = "Passwordless Biometric"
  }
}

resource "okta_user_schema_property" "terms" {
  index       = "terms"
  title       = "Accepted Terms & Conditions"
  type        = "boolean"
  master      = "OKTA"
  permissions = "READ_WRITE"
}

resource "okta_group" "mfa" {
  name        = "Auth: MFA"
  description = "User authenticating with MFA"
}

resource "okta_group" "passwordless_email" {
  name        = "Auth: Passwordless Email"
  description = "User authenticating passwordless using emaill"
}

resource "okta_group" "passwordless_biometric" {
  name        = "Auth: Passwordless Biometric"
  description = "User authenticating passwordless using biometrics"
}

resource "okta_authenticator" "email" {
  name = "Email"
  key  = "okta_email"
  settings = jsonencode({
    "allowedFor" : "any",
    "tokenLifetimeInMinutes" : 5
  })
}

resource "okta_authenticator" "webauthn" {
  name = "Security Key or Biometric"
  key  = "webauthn"
}


resource "okta_policy_mfa" "mfa" {
  name            = "MFA Opt-In"
  status          = "ACTIVE"
  description     = "Force users in mfa group to enroll a second factor"
  groups_included = [okta_group.mfa.id, okta_group.passwordless_email.id, okta_group.passwordless_biometric.id]
  okta_password = {
    enroll = "REQUIRED"
  }
}

resource "okta_policy_rule_mfa" "mfa" {
  policy_id = okta_policy_mfa.mfa.id
  name      = "Allow enrollment"
}

resource "okta_policy_mfa" "passwordless_email" {
  name        = "Passwordless email"
  status      = "ACTIVE"
  description = "Force user to verify an email address to use that for authentication"
  okta_email = {
    enroll = "REQUIRED"
  }
  groups_included = [okta_group.passwordless_email.id]
}

resource "okta_policy_rule_mfa" "passwordless_email" {
  policy_id = okta_policy_mfa.passwordless_email.id
  name      = "Allow enrollment"
}

resource "okta_policy_mfa" "passwordless_biometric" {
  name        = "Passwordless biometric"
  status      = "ACTIVE"
  description = "Force users to enroll a webauthn factor to use that for authentication"
  webauthn = {
    enroll = "REQUIRED"
  }
  // have a backup factor
  okta_password = {
    enroll = "REQUIRED"
  }
  groups_included = [okta_group.passwordless_biometric.id]
}

resource "okta_policy_rule_mfa" "passwordless_biometric" {
  policy_id = okta_policy_mfa.passwordless_biometric.id
  name      = "Allow enrollment"
}

data "okta_default_policy" "default" {
  type = "OKTA_SIGN_ON"
}

resource "okta_policy_rule_signon" "defer" {
  name               = "Defer Authentication to Authentication Policy"
  policy_id          = data.okta_default_policy.default.id
  identity_provider  = "ANY"
  network_connection = "ANYWHERE"
  risc_level         = "ANY"
  authtype           = "ANY"
  primary_factor     = "PASSWORD_IDP_ANY_FACTOR"
}

resource "okta_app_signon_policy" "travel_website" {
  name        = "${var.demo_name} Policy"
  description = "Authentication Policy to be used on the public website"
}

resource "okta_app_signon_policy_rule" "all" {
  policy_id                   = resource.okta_app_signon_policy.travel_website.id
  name                        = "Catch-All Rule"
  factor_mode                 = "1FA"
  re_authentication_frequency = "PT43800H"
  constraints = [
    jsonencode({
      "knowledge" : {
        "types" : ["password"]
      }
    })
  ]
}

resource "okta_app_signon_policy_rule" "mfa" {
  policy_id       = resource.okta_app_signon_policy.travel_website.id
  name            = "MFA Opt-In"
  groups_included = [okta_group.mfa.id]
  factor_mode     = "2FA"
  priority        = 3
  constraints = [
    jsonencode({
      "knowledge" : {
        "types" : ["password"]
      },
      "reauthenticateIn" : "PT43800H"
    })
  ]
}

resource "okta_app_signon_policy_rule" "passwordless_email" {
  policy_id       = resource.okta_app_signon_policy.travel_website.id
  name            = "Passwordless Email"
  groups_included = [okta_group.passwordless_email.id]
  factor_mode     = "1FA"
  priority        = 2
  constraints = [
    jsonencode({
      "posession" : {},
      "reauthenticateIn" : "PT43800H"
    })
  ]
}

resource "okta_app_signon_policy_rule" "passwordless_biometric" {
  policy_id       = resource.okta_app_signon_policy.travel_website.id
  name            = "Passwordless Biometric"
  groups_included = [okta_group.passwordless_biometric.id]
  factor_mode     = "1FA"
  priority        = 1
  constraints = [
    jsonencode({
      "posession" : {
        "deviceBound" : "REQUIRED",
        "phishingResistant" : "REQUIRED"
      },
      "reauthenticateIn" : "PT43800H"
    })
  ]
}

data "okta_auth_server" "default" {
  name = "default"
}

resource "okta_auth_server_scope" "demo" {
  name           = "read:demo"
  auth_server_id = data.okta_auth_server.default.id
  display_name   = "Read access to your data"
  description    = "allows the application to read your user data"
  consent        = "REQUIRED"
}
resource "okta_auth_server_claim" "auth" {
  name           = "auth"
  auth_server_id = data.okta_auth_server.default.id
  scopes         = [okta_auth_server_scope.demo.name]
  value          = "user.auth"
  claim_type     = "IDENTITY"
  value_type     = "EXPRESSION"
}
resource "okta_auth_server_claim" "terms" {
  name           = "terms"
  auth_server_id = data.okta_auth_server.default.id
  scopes         = [okta_auth_server_scope.demo.name]
  value          = "user.terms"
  claim_type     = "IDENTITY"
  value_type     = "EXPRESSION"
}

resource "okta_auth_server_claim" "groups" {
  name              = "groups"
  auth_server_id    = data.okta_auth_server.default.id
  scopes            = [okta_auth_server_scope.demo.name]
  value             = ".*"
  value_type        = "GROUPS"
  claim_type        = "IDENTITY"
  group_filter_type = "REGEX"
}


resource "okta_group_rule" "mfa" {
  name              = "Auth: MFA"
  status            = "ACTIVE"
  group_assignments = [okta_group.mfa.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.auth==\"mfa\""
  depends_on = [
    okta_group.mfa
  ]
}
resource "okta_group_rule" "passwordless_email" {
  name              = "Auth: Passwordless Email"
  status            = "ACTIVE"
  group_assignments = [okta_group.passwordless_email.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.auth==\"passwordless-email\""
  depends_on = [
    okta_group.passwordless_email
  ]
}
resource "okta_group_rule" "passwordless_biometric" {
  name              = "Auth: Passwordless Biometric"
  status            = "ACTIVE"
  group_assignments = [okta_group.passwordless_biometric.id]
  expression_type   = "urn:okta:expression:1.0"
  expression_value  = "user.auth==\"passwordless-biometric\""
  depends_on = [
    okta_group.passwordless_biometric
  ]
}

resource "okta_policy_profile_enrollment" "web" {
  name = "Web Sign Up"
}

resource "okta_policy_rule_profile_enrollment" "web" {
  policy_id = okta_policy_profile_enrollment.web.id
  profile_attributes {
    name     = "email"
    label    = "Email"
    required = true
  }
  profile_attributes {
    name     = "firstName"
    label    = "First name"
    required = true
  }
  profile_attributes {
    name     = "lastName"
    label    = "Last name"
    required = true
  }
  profile_attributes {
    name     = "terms"
    label    = "Accept Terms & Conditions"
    required = true
  }
  unknown_user_action = "REGISTER"
}

resource "okta_policy_profile_enrollment_apps" "web" {
  policy_id = okta_policy_profile_enrollment.web.id
  apps      = [okta_app_oauth.travel_website.id]

}

resource "okta_idp_social" "facebook" {
  name          = "Facebook"
  type          = "FACEBOOK"
  protocol_type = "OAUTH2"
  client_id     = var.idp_social_facebook_client_id
  client_secret = var.idp_social_facebook_client_secret
  scopes        = ["public_profile", "email"]
}
resource "okta_idp_social" "google" {
  name          = "Google"
  type          = "GOOGLE"
  protocol_type = "OIDC"
  client_id     = var.idp_social_google_client_id
  client_secret = var.idp_social_google_client_secret
  scopes        = ["openid", "profile", "email"]
}

data "okta_policy" "default_idp_discovery" {
  type = "IDP_DISCOVERY"
  name = "Idp Discovery Policy"

}

resource "okta_policy_rule_idp_discovery" "okta" {
  idp_type  = "OKTA"
  name      = "okta authentication"
  policy_id = data.okta_policy.default_idp_discovery.id
}
resource "okta_policy_rule_idp_discovery" "facebook" {
  name      = "facebook authentication"
  idp_type  = "FACEBOOK"
  idp_id    = okta_idp_social.facebook.id
  policy_id = data.okta_policy.default_idp_discovery.id
}
resource "okta_policy_rule_idp_discovery" "google" {
  name      = "google authentication"
  idp_type  = "GOOGLE"
  idp_id    = okta_idp_social.google.id
  policy_id = data.okta_policy.default_idp_discovery.id
}

