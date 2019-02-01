import groovy.json.JsonSlurper

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

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

println("Setting HTTP proxy configuration according to registry settings...")
core.removeHTTPProxy()
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
} else {
    println("No HTTP proxy configuration set")
}

println("Setting HTTPS proxy configuration according to registry settings...")
core.removeHTTPSProxy()
// Can only activate HTTPS proxy settings if HTTP is also activated
if (httpsHostAndPortArePresent() && httpHostAndPortArePresent()){
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
} else {
    println("No HTTPS proxy configuration set")
}

println("Setting non-proxy hosts according to registry settings...")
// Can only set non-proxy hosts if HTTP proxy configuration is set
if (nonProxyHostsArePresent() && httpHostAndPortArePresent()){
    String[] nonProxyHosts = configurationParameters.proxyConfigurationNonProxyHosts.split(",")
    core.nonProxyHosts(nonProxyHosts)
} else {
    println("No non-proxy hosts configuration set")
}
