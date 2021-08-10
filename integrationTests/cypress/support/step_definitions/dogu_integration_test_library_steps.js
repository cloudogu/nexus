// Loads all steps from the dogu integration library into this project
const doguTestLibrary = require('@cloudogu/dogu-integration-test-library')
doguTestLibrary.registerSteps()

When(/^the user clicks the dogu logout button$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#nx-header-signout-1144-btnEl').click();
});

Then(/^the user has administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#button-1125-btnIconEl').should('be.visible')
});

Then(/^the user has no administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#button-1125-btnIconEl').should('not.be.visible')
});
