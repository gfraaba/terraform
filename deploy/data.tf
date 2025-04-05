# data block to read the output of the local terraform state file
data "terraform_remote_state" "state" {
  backend = "local"
  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}