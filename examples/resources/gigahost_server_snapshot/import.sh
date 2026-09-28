# Find the server ID and snapshot ID:
#   gigahost servers list
#   gigahost servers snapshots list SERVER_ID
terraform import gigahost_server_snapshot.example SERVER_ID/SNAPSHOT_ID
