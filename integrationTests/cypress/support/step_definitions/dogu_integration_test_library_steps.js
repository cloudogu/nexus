// Loads all steps from the dogu integration library into this project
const doguTestLibrary = require('@cloudogu/dogu-integration-test-library')
doguTestLibrary.registerSteps()

When(/^the user clicks the dogu logout button$/, function () {
    cy.get('#nx-header-signout-1144-btnEl').click();
});

Then(/^the user has administrator privileges in the dogu$/, function () {
    cy.get('#button-1125-btnIconEl').should('be.visible')
});

Then(/^the user has no administrator privileges in the dogu$/, function () {
    cy.get('#button-1125-btnIconEl').should('not.be.visible')
});
