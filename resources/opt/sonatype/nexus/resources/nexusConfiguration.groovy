import org.sonatype.nexus.capability.CapabilityRegistry
import org.sonatype.nexus.capability.CapabilityType
import org.sonatype.nexus.security.realm.RealmManager
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

def securitySystem = security.getSecuritySystem()

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

println("Creating ces admin group role")
authorizationManager = securitySystem.getAuthorizationManager('default')
role = new org.sonatype.nexus.security.role.Role(
    roleId: configurationParameters.adminGroup,
    source: "Nexus",
    name: configurationParameters.adminGroup,
    description: "Administrator of CES",
    readOnly: false,
    privileges: [ "nx-all" ],
    roles: []
)
authorizationManager.addRole(role)

println("Changing admin password")
securitySystem.changePassword("admin", configurationParameters.defaultAdminPassword, configurationParameters.newAdminPassword)
