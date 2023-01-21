variable "model" {
  description = "Model data."
  type        = any
}

variable "tenant_name" {
  description = "Tenant name."
  type        = string
}

variable "dependencies" {
  description = "This variable can be used to express explicit dependencies between modules."
  type        = list(string)
  default     = []
}
