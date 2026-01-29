import org.sonatype.nexus.repository.config.ConfigurationStore

// Die benötigten Dienste müssen erst über den 'container' gesucht werden
def configStore = container.lookup('org.sonatype.nexus.repository.config.ConfigurationStore')

if (!configStore) {
    log.error "FEHLER: ConfigurationStore konnte nicht geladen werden."
    return
}


configStore.list().each { config ->
    boolean changed = false
    // Wir arbeiten auf einer Kopie der Attribute, um Nebeneffekte zu vermeiden
    def attributes = config.attributes

    attributes.each { key, attr ->
        if (attr instanceof Map && attr['authentication'] != null) {
            def auth = attr['authentication']
            def encryptedPassword = auth['password']

            if (encryptedPassword && encryptedPassword != "") {
                log.info "Verarbeite Repository: ${config.repositoryName}"
                auth['password'] = "password"
                changed = true
            }
        }
    }

    if (changed) {
        configStore.update(config)
        log.info "Repository '${config.repositoryName}' wurde erfolgreich für die Migration vorbereitet."
    }
}