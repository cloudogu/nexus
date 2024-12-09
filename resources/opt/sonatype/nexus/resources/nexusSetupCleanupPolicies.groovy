import org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def Integer asSeconds(Integer days) {
    return days * 60 * 60 * 24
}

def String asStringSeconds(String daysString) {
    return String.valueOf(asSeconds(Integer.parseInt(daysString)))
}

/**
 * this script is called in startup.sh and creates a cleanup
 * @return
 */
def createMavenSnapshotCleanupPolicy(configurationParameters) {
    def policyStorage = container.lookup(CleanupPolicyStorage.class.getName())

    def cleanupPolicy = policyStorage.newCleanupPolicy()
    cleanupPolicy.setName(configurationParameters.name)
    cleanupPolicy.setNotes(configurationParameters.notes)
    cleanupPolicy.setMode(configurationParameters.mode)
    cleanupPolicy.setFormat(configurationParameters.format)

    def criteriaMap = [:]
    criteriaMap.put('regex', configurationParameters.criteria.regex) // criteriaAssetRegex
    if (configurationParameters.criteria.criteriaReleaseType != "") {
        // We do a additional check here as the criteriaReleaseType is not supported for every kind of repository
        // and should therefore be only set if a value is present.
        // see: https://help.sonatype.com/repomanager3/nexus-repository-administration/repository-management/cleanup-policies
        criteriaMap.put('isPrerelease', "PRERELEASES".equals(configurationParameters.criteria.criteriaReleaseType).toString())
    }
    criteriaMap.put('lastBlobUpdated', asStringSeconds(configurationParameters.criteria.criteriaLastBlobUpdated))

    cleanupPolicy.setCriteria(criteriaMap)

    deleteCleanupPolicyIfExists(configurationParameters.name)
    policyStorage.add(cleanupPolicy)
}

def deleteCleanupPolicyIfExists(String name) {
    def cleanupPolicyStorage = container.lookup(CleanupPolicyStorage.class.getName())
    if (cleanupPolicyStorage.exists(name)) {
        cleanupPolicyStorage.remove(cleanupPolicyStorage.get(name))
    }
}

// start
createMavenSnapshotCleanupPolicy(configurationParameters)