const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");

//
//
// Given
//
//

Given(/^the user is not member of the admin user group$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    // default behaviour
});

Given(/^the user is member of the admin user group$/, function () {
    Cypress.on('uncaught:exception', () => { return false; }); // Catch nexus errors and prevent test from failing
    cy.fixture("testuser_data").then(function (testUser) {
        cy.promoteAccountToAdmin(testUser.username)
    })
});
//
//
// When
//
//

When(/^the user clicks the logout button$/, function () {
    cy.get('#nx-header-signout-1144-btnEl').click();
});

//
//
// Then
//
//

Then(/^the user can see administration icon$/, function () {
    cy.get('#button-1125-btnIconEl').should('be.visible')
});

Then(/^the user cannot see administration icon$/, function () {
    cy.get('#button-1125-btnIconEl').should('not.be.visible')
});
