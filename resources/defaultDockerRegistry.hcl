repository "docker-registry" {
  online = true
  recipeName = "docker-hosted"
  attributes = {
    docker = {
      forceBasicAuth = true
      v1Enabled = false
    }
    storage = {
        blobStoreName = "default"
        strictContentTypeValidation = true
        writePolicy = "ALLOW"
    }
  }
  _state = "present"
}
