# Vault CLI Example

## Set ENV
```bash
export VAULT_ADDR=http://yourVaultAddress:8200
export VAULT_TOKEN=<your root token>
export VAULT_NAMESPACE=<new namespace> // If Enterprise
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

## Admin User/Pass


1. userpass 활성화

   ```bash
   $ vault auth enable userpass
   ```

   

2. 권한 추가 (e.g. super-user)

   ```bash
   $ vault policy write super-user - << EOF
   path "*" {
   capabilities = ["create", "read", "update", "delete", "list", "sudo"]
   }
   EOF
   ```

   

3. 계정 생성

   ```bash
   $ vault write auth/userpass/users/myadmin password=mypassword policies=super-user
   # vault token create -policy=super-user
   ```



4. 로그인

   ```bash
   $ vault login -method userpass username=myadmin password=mypassword
   ```

## Create KV alicloud Key and Dev/Prod
```bash
vault login -method userpass username=myadmin password=mypassword

vault secrets enable -path=kv-alicloud kv
echo '{"access_key":"alibaba_access_key", "secret_key":"alibaba_secret_key"}' | vault kv put kv-alicloud/key2 -

vault secrets enable -path=kv-immutable kv
vault kv put kv-immutable/dev/conf url="placekitten.com"
vault kv put kv-immutable/prod/conf url="place.dog"
```

## Dev/Prod User and policy

1. 권한 추가 (e.g. super-user)

   ```bash
   $ vault policy write dev-user - << EOF
   path "kv-alicloud/*" {
     capabilities = ["read"]
   }
   path "kv-immutable/+/+" {
     capabilities = ["list"]
   }
   path "kv-immutable/+/dev/*" {
     capabilities = ["list"]
   }
   path "kv-immutable/data/dev/*" {
     capabilities = ["create", "read", "update", "delete", "list"]
   }
   EOF

   $ vault policy write prod-user - << EOF
   path "kv-alicloud/*" {
     capabilities = ["read"]
   }
   path "kv-immutable/+/+" {
     capabilities = ["list"]
   }
   path "kv-immutable/+/prod/*" {
     capabilities = ["list"]
   }
   path "kv-immutable/data/prod/*" {
     capabilities = ["create", "read", "update", "delete", "list"]
   }
   EOF
   ```

2. 계정 생성

   ```bash
   $ vault write auth/userpass/users/devuser password=devpassword policies=dev-user
   # vault token create -policy=dev-user
   $ vault write auth/userpass/users/produser password=prodpassword policies=prod-user
   # vault token create -policy=prod-user
   ```