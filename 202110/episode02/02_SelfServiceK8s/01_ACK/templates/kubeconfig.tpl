apiVersion: v1
preferences: {}
kind: Config

clusters:
- cluster:
    server: ${endpoint}
    certificate-authority-data: ${ca_data}
  name: kubernetes

contexts:
- context:
    cluster: kubernetes
    user: "${user_id}"
  name: ${user_id}-${cluster_id}

current-context: ${user_id}-${cluster_id}

users:
- name: "${user_id}"
  user:
    client-certificate-data: ${cert_data}
    client-key-data: ${key_data}