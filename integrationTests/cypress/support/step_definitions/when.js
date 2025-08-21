const {
    When
} = require("@badeball/cypress-cucumber-preprocessor");


When(/^the user clicks the logout button$/, function () {
    cy.get('[data-analytics-id="nxrm-global-header-profile-menu"]').click();
    cy.get('div.nx-dropdown-menu')
        .find('button.nx-dropdown-button')
        .click()
});
