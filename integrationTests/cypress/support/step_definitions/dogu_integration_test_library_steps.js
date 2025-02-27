const {
    When,
    Then
} = require("@badeball/cypress-cucumber-preprocessor");

// Loads all steps from the dogu integration library into this project
const doguTestLibrary = require('@cloudogu/dogu-integration-test-library');
doguTestLibrary.registerSteps();

When(/^the user clicks the dogu logout button$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#nx-header-signout-1152-btnEl').click();
});

Then(/^the user has administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#nx-header-mode-1132-innerCt').should('be.visible')
});

Then(/^the user has no administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('#nx-header-mode-1132-innerCt').should('not.be.visible')
});
