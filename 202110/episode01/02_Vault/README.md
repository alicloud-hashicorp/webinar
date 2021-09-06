# Vault

## Vault init

```bash
vault operator init -key-shares=1 -key-threshold=1 -tls-skip-verify > ~/key.txt

export VAULT_SKIP_VERIFY=True
export VAULT_ADDR=https://47.241.92.118:8200
export VAULT_TOKEN=s.YVK2mjCvf2A5wWaOA8Sy22hC

vault auth enable userpass
vault policy write super-user - << EOF
path "*" {
capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}
EOF

vault write auth/userpass/users/admin password=password policies=super-user
```

## Vault SSH OTP

```bash
vault secrets enable -path ssh-otp ssh

vault write ssh-otp/roles/otp_key_role \
    key_type=otp \
    default_user=test \
    allowed_users=test \
    key_bits=2048 \
    cidr_list=0.0.0.0/0
```