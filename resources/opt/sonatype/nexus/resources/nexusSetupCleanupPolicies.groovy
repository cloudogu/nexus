import org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage
import org.sonatype.nexus.
/**
 * this script is called in startup.sh and creates a cleanup
 * @return
 */
def createMavenSnapshotCleanupPolicy() {
    try {
        def policyStorage = container.lookup(CleanupPolicyStorage.class.getName())
        def cleanupPolicy = policyStorage.newCleanupPolicy()
        cleanupPolicy.setName("maven-snapshot-cleanuppolicy")
        cleanupPolicy.setNotes('')
        cleanupPolicy.setMode('deletion')
        cleanupPolicy.setFormat('maven2')
        cleanupPolicy.setCriteria(['regex': '.*SNAPSHOT', 'criteriaReleaseType': 'PRERELEASES'])
        policyStorage.add(cleanupPolicy)
    } catch (e) {
        log.info("An error occurred while creating the policy. It might already exists, skipping...")
        return e
    }
}

// start
createMavenSnapshotCleanupPolicy()