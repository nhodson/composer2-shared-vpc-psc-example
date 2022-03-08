variable "org_id" {
  type = string
}

variable "billing_account_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "project_prefix" {
  type = string
}

variable "provider_project" {
  type = string
}

variable "terraform_service_account" {
  type = string
}

variable "host_project_id" {
  type = string
}

variable "svpc_network" {
  type = string
}

variable "svpc_subnet" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "svcs_range_name" {
  type = string
}