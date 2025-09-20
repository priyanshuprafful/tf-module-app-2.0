terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "3.2.3"
    }
  }
}
resource "null_resource" "test" {
  provisioner "local-exec" {
    command = "echo Hello All - Env - ${var.env}"
  }
}
