{
  "active": "{{ .Config.GetOrDefault "secret_encryption/active" "null"}}",
  "keys": [
    {
      "id": "{{ .Config.GetOrDefault "secret_encryption/id" "null"}}",
      "key": "{{ .Config.GetOrDefault "secret_encryption/key" "null"}}"
    }
  ]
}