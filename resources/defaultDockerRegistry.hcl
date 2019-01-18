repository "docker-registry" {
  id = "docker-registry"
  format = "docker"
  type = "hosted"
  repositoryName = "docker-registry"
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