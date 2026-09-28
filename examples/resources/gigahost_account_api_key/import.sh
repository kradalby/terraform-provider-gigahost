# Find the key ID (the ID column, not the prefix):
#   gigahost account api-keys list
# NOTE: the secret is shown only once at creation and cannot be recovered by
# import. After import the secret attribute will be null in state; manage the
# secret out-of-band and supply it via a variable if needed.
terraform import gigahost_account_api_key.example KEY_ID
