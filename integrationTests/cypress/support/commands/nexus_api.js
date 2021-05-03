const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables');

/**
 * Accesses the scripting api of nexus with get
 * @param {String} username - Username for login
 * @param {String} password - Password for login
 * @param {boolean} exitOnFail - Determines whether the test should fail when the request did not succeed. Default: false
 */
const nexusRequestScriptingApi = (username, password, exitOnFail = false) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + "/nexus/service/rest/v1/script",
        auth: {
            'user': username,
            'pass': password
        },
        failOnStatusCode: exitOnFail
    })
}

/**
 * Deletes a user from the dogu via an API call.
 * @param {String} username - The username of the user.
 * @param {boolean} exitOnFail - Determines whether the test should fail when the request did not succeed. Default: false
 */
const deleteUserFromDoguViaAPI = (username, exitOnFail = false) => {
    return cy.request({
        method: "GET",
        url: Cypress.config().baseUrl + `/nexus/service/rest/v1/users/${username}`,
        auth: {
            'user': env.GetAdminUsername(),
            'pass': env.GetAdminPassword()
        },
        failOnStatusCode: exitOnFail
    })
}

Cypress.Commands.add("deleteUserFromDoguViaAPI", deleteUserFromDoguViaAPI)
Cypress.Commands.add("nexusRequestScriptingApi", nexusRequestScriptingApi)

