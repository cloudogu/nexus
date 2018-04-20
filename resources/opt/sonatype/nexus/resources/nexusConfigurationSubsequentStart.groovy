import org.sonatype.nexus.capability.*
import org.sonatype.nexus.security.realm.RealmManager
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

println("Setting base URL")
core.baseUrl("https://" + configurationParameters.fqdn + "/nexus")
