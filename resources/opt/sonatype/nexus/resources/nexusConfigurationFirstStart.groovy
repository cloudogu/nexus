import org.sonatype.nexus.capability.CapabilityRegistry
import org.sonatype.nexus.capability.CapabilityType
import org.sonatype.nexus.security.realm.RealmManager
import org.sonatype.nexus.security.SecuritySystem
import groovy.json.JsonSlurper

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

println("Enabling rutauth-realm")
realmManager = container.lookup(RealmManager.class.getName())
realmManager.enableRealm("rutauth-realm")

println("Add rutauth capability")
capabilityRegistry = container.lookup(CapabilityRegistry.class)
Map properties = new HashMap<String, String>();
properties.put("httpHeader", "X-CARP-Authentication")
def existing = capabilityRegistry.all.find { it.type().toString() == "rutauth" }
if (existing) {
    capabilityRegistry.update(existing.id(), existing.active, existing.notes(), properties)
} else {
    capabilityType = new CapabilityType("rutauth")
    capabilityRegistry.add(capabilityType, true, null, properties)
}

if (configurationParameters.disableOutreachManagement == "true") {
    for (c in capabilityRegistry.getAll()) {
        if (c.context().type().toString().startsWith("OutreachManagementCapability")) {
            log.info("Disable outreach capability")
            capabilityRegistry.disable(c.context().id())
        }
    }
}

println("Setting base URL")
core.baseUrl("https://" + configurationParameters.fqdn + "/nexus")

println("Disabling anonymous access")
security.setAnonymousAccess(false)

println("Creating ces admin group role")
security.addRole(configurationParameters.adminGroup, configurationParameters.adminGroup, "Administrator of CES", [ "nx-all" ], [])

println("Creating default ces user role")
security.addRole("cesUser", "cesUser", "User of CES", ["nx-healthcheck-read", "nx-healthcheck-summary-read", "nx-repository-view-*-*-browse", "nx-repository-view-*-*-add", "nx-repository-view-*-*-read", "nx-search-read", "nx-userschangepw", "nx-apikey-all"], [])

println("Changing admin password")
def securitySystem = container.lookup(SecuritySystem.class.getName())
securitySystem.changePassword("admin", configurationParameters.newAdminPassword)
