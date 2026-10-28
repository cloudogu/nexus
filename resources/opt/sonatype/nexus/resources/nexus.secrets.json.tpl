{
  "active": "{{ .Config.GetOrDefault "secret_encryption/active" "null"}}",
  "keys": [
    {
      "id": "{{ .Config.GetOrDefault "secret_encryption/id" "null"}}",
      "key": "{{ if .Config.Exists "secret_encryption/key" }}{{ .Config.GetAndDecrypt "secret_encryption/key" }}{{ else }}null{{ end }}"
    }
  ]
}