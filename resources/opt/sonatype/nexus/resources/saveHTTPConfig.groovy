def configStore = container.lookup('org.sonatype.nexus.repository.config.ConfigurationStore')

if (!configStore) {
    log.error "KRITISCH: ConfigurationStore konnte nicht gefunden werden!"
    return
}

int count = 0

configStore.list().each { config ->
    def repoName = config.repositoryName
    boolean changed = false

    // Wir durchsuchen alle Attribut-Gruppen (proxy, httpclient, etc.)
    config.attributes.each { attrKey, attrValue ->
        if (attrValue instanceof Map && attrValue['authentication'] != null) {
            log.info "Entferne HTTP-Authentifizierung für Repository: ${repoName} (Gefunden in: ${attrKey})"

            // Die gesamte Authentifizierungs-Map entfernen
            attrValue.remove('authentication')
            changed = true
        }
    }

    if (changed) {
        configStore.update(config)
        count++
    }
}

log.info "ABGESCHLOSSEN: Authentifizierung aus ${count} Repositories entfernt."