variable "image_tag" {
  type        = string
  description = "Ceramic/IPFS image tag"
  default     = "prod"
}

variable "project" {
  type    = string
  default = "metaphor-app"
}

variable "region" {
  type    = string
  default = "us-east4"
}

variable "zone" {
  type    = string
  default = "us-east4-b"
}

variable "machine_type" {
  type    = string
  default = "e2-standard-2"
}

variable "ceramic_network" {
  type    = string
  default = "testnet-clay"
}
