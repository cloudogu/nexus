import groovy.json.JsonSlurper
import org.sonatype.nexus.capability.*

static def removeAdminPrivilege(role) {
    def privs = role.getPrivileges()

    privs.remove("nx-all")
    role.setPrivileges(privs)
}

// get parameters from payload JSON file
def configurationParameters = new JsonSlurper().parseText(args)

println("Setting base URL")
core.baseUrl("https://" + configurationParameters.fqdn + "/nexus")

def adminGroup = configurationParameters.adminGroup
def lastAdminGroup = configurationParameters.lastAdminGroup

if (!adminGroup.equals(lastAdminGroup) && !lastAdminGroup.equals("")) {
    def securitySystem = security.getSecuritySystem()
    def authManager = securitySystem.getAuthorizationManager('default')

    def adminRole = null

    try {
        adminRole = authManager.getRole(adminGroup)
        adminRole.addPrivilege("nx-all")

        println("persisting new admin role after updating it")
        authManager.updateRole(adminRole)
    } catch (org.sonatype.nexus.security.role.NoSuchRoleException e) {
        println("role " + adminRole + " does not exist, creating")

        adminRole = new org.sonatype.nexus.security.role.Role(
                roleId: adminGroup,
                source: "CAS",
                name: adminGroup,
                description: "Administrator of CES",
                readOnly: false,
                privileges: ["nx-all"],
                roles: []
        )

        println("persisting new admin role after creating it")
        authManager.addRole(adminRole)
    }

    println("removing admin privilege from last admin group")
    try {
        def lastAdminRole = authManager.getRole(lastAdminGroup)
        removeAdminPrivilege(lastAdminRole)
        authManager.updateRole(lastAdminRole)
    } catch (org.sonatype.nexus.security.role.NoSuchRoleException e) {
        println("last admin group " + lastAdminGroup + " does not exist. Ignoring")
    }
}
