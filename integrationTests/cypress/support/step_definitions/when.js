const {
    When
} = require("@badeball/cypress-cucumber-preprocessor");


When(/^the user clicks the logout button$/, function () {
    cy.get('#nx-header-signout-1144-btnEl').click();
});

