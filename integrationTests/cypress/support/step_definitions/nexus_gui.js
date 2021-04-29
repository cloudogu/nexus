const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables');

//
//
// When
//
//

When(/^the user clicks the logout button$/, function () {
    cy.get('#nx-header-signout-1144-btnEl').click();
    console.log(env.GetAdminUsername());
    cy.redmineDeleteUser();
});
