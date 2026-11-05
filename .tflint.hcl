# tflint: catches mistakes `terraform validate` can't (invalid VM sizes,
# deprecated syntax, unused variables, missing descriptions...).
#   tflint --init && tflint --recursive

config {
  # Also lint the local modules when linting envs/* and bootstrap/.
  call_module_type = "local"
}

plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

plugin "azurerm" {
  enabled = true
  version = "0.33.0"
  source  = "github.com/terraform-linters/tflint-ruleset-azurerm"
}
