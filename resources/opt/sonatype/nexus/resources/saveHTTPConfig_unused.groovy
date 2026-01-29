import groovy.json.JsonBuilder
import java.io.File
import java.lang.reflect.Field

// --- SCHRITT 1: Aggressive Suche nach dem PasswordHelper im gesamten Container ---
def findHelper(container, log) {
    def helper = null
    try {
        // Wir fragen den BeanLocator nach allen Komponenten und suchen nach dem Namen
        container.beanLocator.locate(com.google.inject.Key.get(Object)).each { bean ->
            if (bean.description.contains("PasswordHelper")) {
                log.info "Helper-Kandidat gefunden: ${bean.description}"
                try {
                    helper = bean.getValue()
                } catch (e) {}
            }
        }
    } catch (e) {
        log.error "Fehler bei der Komponentensuche: ${e.message}"
    }
    return helper
}

// --- SCHRITT 2: Reflection-Trick um die Maskierung zu umgehen ---
def getUnmaskedValue(map, key, log) {
    def value = map[key]
    if (value == "_1") {
        log.info "Wert für '${key}' ist maskiert. Versuche Reflection..."
        try {
            // Bei vielen Nexus-Versionen ist die Map eine 'NestedAttributesMap'
            // Wir versuchen an das interne 'backing' Feld heranzukommen
            Field field = map.getClass().getDeclaredField("backing")
            field.setAccessible(true)
            def backingMap = field.get(map)
            return backingMap[key]
        } catch (e) {
            log.warn "Reflection fehlgeschlagen: ${e.message}"
        }
    }
    return value
}

def log = log
def passwordHelper = findHelper(container, log)
def configStore = container.lookup('org.sonatype.nexus.repository.config.ConfigurationStore')
def backupFile = new File('/var/lib/nexus/http_auth_backup.json')
def backupData = [:]

if (!passwordHelper) {
    log.error "KRITISCH: PasswordHelper konnte absolut nicht gefunden werden!"
}

configStore.list().each { config ->
    def repoName = config.repositoryName
    config.attributes.each { attrKey, attrValue ->
        if (attrValue instanceof Map && attrValue['authentication'] != null) {
            def authMap = attrValue['authentication']

            // Versuche den unmaskierten (verschlüsselten) Wert zu bekommen
            def rawPassword = getUnmaskedValue(authMap, 'password', log)

            if (rawPassword && rawPassword != "_1") {
                def finalPassword = rawPassword
                if (passwordHelper) {
                    try {
                        finalPassword = passwordHelper.decrypt(rawPassword)
                        log.info "ERFOLG: Passwort für ${repoName} entschlüsselt."
                    } catch (e) {
                        log.warn "Entschlüsselung fehlgeschlagen (Password eventuell bereits Klartext?): ${e.message}"
                    }
                }

                backupData[repoName] = [
                        attributeKey: attrKey,
                        username: authMap['username'],
                        password: finalPassword,
                        type: authMap['type']
                ]

                // Entfernen für das Update
                authMap.remove('authentication')
                configStore.update(config)
            } else {
                log.error "FEHLER: Passwort für ${repoName} konnte nicht unmaskiert werden."
            }
        }
    }
}

if (backupData.size() > 0) {
    backupFile.text = new JsonBuilder(backupData).toPrettyString()
    log.info "BACKUP FERTIG: ${backupData.size()} Einträge gespeichert."
}