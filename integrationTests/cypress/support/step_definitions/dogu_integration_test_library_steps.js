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
    cy.get('[data-analytics-id="nxrm-global-header-profile-menu"]').click();
    cy.get('div.nx-dropdown-menu')
        .find('button.nx-dropdown-button')
        .click()
});

Then(/^the user has administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('a[href="#admin/repository"]').should('exist')
});

Then(/^the user has no administrator privileges in the dogu$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fullyLoadPageAndClosePopups()
    cy.get('a[href="#admin/repository"]').should('not.exist')
});
