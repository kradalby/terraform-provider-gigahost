data "gigahost_account" "example" {}

output "account_email" {
  value = data.gigahost_account.example.email
}
