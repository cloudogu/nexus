import org.sonatype.nexus.capability.CapabilityRegistry
import org.sonatype.nexus.capability.CapabilityType
import org.sonatype.nexus.security.realm.RealmManager

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
core.baseUrl("https://192.168.56.2/nexus")

println("Disabling anonymous access")
security.setAnonymousAccess(false)

println("Changing admin password")
security.getSecuritySystem().changePassword("admin", "admin123", "admin1234")
