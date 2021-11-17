terraform {
  required_providers {
    azuread = {
      source = "hashicorp/azuread"
      version = "~>2"
    }
  }
}

variable "departments" {
  type = map(list(string))
}

locals {
  default_password_slug = "3864!changeMe"
}

data "azuread_domains" "default" {
  only_default = true
}

resource "azuread_user" "staff" {
  for_each = toset(flatten([for p in var.departments: p]))
  display_name = title(each.key)
  user_principal_name = "${each.key}@${data.azuread_domains.default.domains[0].domain_name}"
  password = "${replace(each.key, "/(.)/", "$1-")}${local.default_password_slug}"
}

resource "azuread_group" "departments" {
  for_each = var.departments
  display_name = title(each.key)
  mail_nickname = each.key
  types = ["Unified"]
  mail_enabled = true
  security_enabled = true
  members = [for m in each.value: azuread_user.staff[m].object_id]
}
