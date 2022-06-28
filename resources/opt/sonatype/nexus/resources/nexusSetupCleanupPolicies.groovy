import org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

/**
 * this script is called in startup.sh and creates a cleanup
 * @return
 */
def createMavenSnapshotCleanupPolicy(configurationParameters) {
    try {
        def policyStorage = container.lookup(CleanupPolicyStorage.class.getName())


        if (policyStorage.exists(configurationParameters.name)) {
            return
        }

        def cleanupPolicy = policyStorage.newCleanupPolicy()
        cleanupPolicy.setName(configurationParameters.name)
        cleanupPolicy.setNotes(configurationParameters.notes)
        cleanupPolicy.setMode(configurationParameters.mode)
        cleanupPolicy.setFormat(configurationParameters.format)


        def criteriaMap = [:]
        criteriaMap.put("regex", configurationParameters.criteria.regex)
        criteriaMap.put("criteriaReleaseType", configurationParameters.criteria.criteriaReleaseType)
        criteriaMap.put("criteriaLastBlobUpdated", configurationParameters.criteria.criteriaLastBlobUpdated)
        cleanupPolicy.setCriteria(criteriaMap)

        policyStorage.add(cleanupPolicy)

    } catch (e) {
        log.info("An error occurred while creating the cleanup policy " + configurationParameters.name + ". It might already exists, skipping...")
        return e
    }
}

// start
createMavenSnapshotCleanupPolicy(configurationParameters)