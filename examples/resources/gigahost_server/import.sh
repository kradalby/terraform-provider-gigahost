# Find the server ID:
#   gigahost servers list
# NOTE: password and ssh_keys cannot be recovered by import; leave them
# unset or supply known values in your configuration.
# NOTE: type/size are not round-tripped from the API. The first apply after
# import runs an adoption check: the configured type/size are verified against
# the live machine's cores/RAM. A genuine mismatch fails loudly instead of
# silently replacing the server — supply a config that matches the live server.
# NOTE: the computed deploy facts (memory_gb, storage_gb, rate_hourly,
# rate_monthly) are null right after import; they are filled from the live
# catalog during that first apply (adoption).
terraform import gigahost_server.example SERVER_ID
