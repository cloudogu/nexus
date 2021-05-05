const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables');

//
//
// Then
//
//

Then(/^the user can access scripts api$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.nexusRequestScriptingApi(testUser.username, testUser.password).then((response) => {
            expect(response.status).to.eq(200)
        });
    })
});

Then(/^the user cannot access scripts api (403)$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.nexusRequestScriptingApi(testUser.username, testUser.password).then((response) => {
            expect(response.status).to.eq(403)
        });
    })
});
