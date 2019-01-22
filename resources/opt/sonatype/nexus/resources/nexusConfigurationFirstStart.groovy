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
    source: "CAS",
    name: configurationParameters.adminGroup,
    description: "Administrator of CES",
    readOnly: false,
    privileges: [ "nx-all" ],
    roles: []
)
authorizationManager.addRole(role)

println("Creating default ces user role")
authorizationManager = securitySystem.getAuthorizationManager('default')
role = new org.sonatype.nexus.security.role.Role(
    roleId: "cesUser",
    source: "CAS",
    name: "cesUser",
    description: "User of CES",
    readOnly: false,
    privileges: [
                "nx-healthcheck-read",
                "nx-healthcheck-summary-read",
                "nx-repository-view-*-*-browse",
                "nx-repository-view-*-*-add",
                "nx-search-read",
                "nx-userschangepw",
                "nx-apikey-all"],
    roles: []
)
authorizationManager.addRole(role)

securitySystem.changePassword("admin", configurationParameters.defaultAdminPassword, configurationParameters.newAdminPassword)

// Methods for HTTP(S) proxy settings
def httpHostAndPortArePresent() {
    return args.contains("proxyConfigurationHttpHost") && args.contains("proxyConfigurationHttpPort")
}
def httpBasicAuthConfigIsPresent() {
    return args.contains("proxyConfigurationHttpAuthenticationUsername") && args.contains("proxyConfigurationHttpAuthenticationPassword")
}
def httpNtlmConfigIsPresent() {
    return args.contains("proxyConfigurationHttpAuthenticationNtlmHost") && args.contains("proxyConfigurationHttpAuthenticationDomain")
}
def httpsHostAndPortArePresent() {
    return args.contains("proxyConfigurationHttpsHost") && args.contains("proxyConfigurationHttpsPort")
}
def httpsBasicAuthConfigIsPresent() {
    return args.contains("proxyConfigurationHttpsAuthenticationUsername") && args.contains("proxyConfigurationHttpsAuthenticationPassword")
}
def httpsNtlmConfigIsPresent() {
    return args.contains("proxyConfigurationHttpsAuthenticationNtlmHost") && args.contains("proxyConfigurationHttpsAuthenticationDomain")
}
def nonProxyHostsArePresent() {
    return args.contains("proxyConfigurationNonProxyHosts")
}

println("Setting HTTP proxy configuration")
if (httpHostAndPortArePresent()){
    String host = configurationParameters.proxyConfigurationHttpHost
    int port = configurationParameters.proxyConfigurationHttpPort as int
    if (httpBasicAuthConfigIsPresent()){
        String username = configurationParameters.proxyConfigurationHttpAuthenticationUsername
        String password = configurationParameters.proxyConfigurationHttpAuthenticationPassword
        if (httpNtlmConfigIsPresent()){
            String ntlmHost = configurationParameters.proxyConfigurationHttpAuthenticationNtlmHost
            String domain = configurationParameters.proxyConfigurationHttpAuthenticationDomain
            core.httpProxyWithNTLMAuth(host, port, username, password, ntlmHost, domain)
        } else {
            core.httpProxyWithBasicAuth(host, port, username, password)
        }
    } else {
        core.httpProxy(host, port)
    }
}

println("Setting HTTPS proxy configuration")
if (httpsHostAndPortArePresent()){
    String httpshost = configurationParameters.proxyConfigurationHttpsHost
    int httpsport = configurationParameters.proxyConfigurationHttpsPort as int
    if (httpsBasicAuthConfigIsPresent()){
        String httpsusername = configurationParameters.proxyConfigurationHttpsAuthenticationUsername
        String httpspassword = configurationParameters.proxyConfigurationHttpsAuthenticationPassword
        if (httpsNtlmConfigIsPresent()){
            String httpsntlmHost = configurationParameters.proxyConfigurationHttpsAuthenticationNtlmHost
            String httpsdomain = configurationParameters.proxyConfigurationHttpsAuthenticationDomain
            core.httpsProxyWithNTLMAuth(httpshost, httpsport, httpsusername, httpspassword, httpsntlmHost, httpsdomain)
        } else {
            core.httpsProxyWithBasicAuth(httpshost, httpsport, httpsusername, httpspassword)
        }
    } else {
        core.httpsProxy(httpshost, httpsport)
    }
}

println("Setting non-proxy hosts")
if (nonProxyHostsArePresent()){
    String[] nonProxyHosts = configurationParameters.proxyConfigurationNonProxyHosts.split(",")
    core.nonProxyHosts(nonProxyHosts)
}
