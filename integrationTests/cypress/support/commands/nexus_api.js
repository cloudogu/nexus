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

Cypress.Commands.add("nexusRequestScriptingApi", nexusRequestScriptingApi)
