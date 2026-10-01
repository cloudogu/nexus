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
    cy.get('[data-analytics-id="nxrm-header-user-menu"]').click();
    cy.get('[data-analytics-id="nxrm-header-sign-out"]').click();
    // carp redirects to the CAS logout a second after the click. The next step
    // visits the dogu and still finds a valid session if we return before that,
    // so wait well past carp's own delay.
    cy.wait(5000)
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
