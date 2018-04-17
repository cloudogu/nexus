import org.sonatype.nexus.capability.CapabilityRegistry
import org.sonatype.nexus.capability.CapabilityType
import org.sonatype.nexus.security.realm.RealmManager
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

println("Enabling rutauth-realm")
realmManager = container.lookup(RealmManager.class.getName())
realmManager.enableRealm("rutauth-realm")

println("Add rutauth capability")
capabilityRegistry = container.lookup(CapabilityRegistry.class)
capabilityType = new CapabilityType("rutauth")
Map properties = new HashMap<String, String>();
properties.put("httpHeader", "X-CARP-Authentication")
capabilityRegistry.add(capabilityType, true, null, properties)

println("Setting base URL")
core.baseUrl("https://" + configurationParameters.fqdn + "/nexus")

println("Disabling anonymous access")
security.setAnonymousAccess(false)

println("Changing admin password")
security.getSecuritySystem().changePassword("admin", configurationParameters.defaultAdminPassword, configurationParameters.newAdminPassword)
