repository "docker-registry" {
  name = "docker-registry"
  online = true
  recipeName = "docker-hosted"
  attributes = {
    storage = {
        blobStoreName = "default"
        strictContentTypeValidation = true
        writePolicy = "ALLOW"
    }
  }
  _state = "present"
}