const {
    Given,
    When,
    Then
} = require("cypress-cucumber-preprocessor/steps");
const env = require('@cloudogu/dogu-integration-test-library/lib/environment_variables');

//
//
// Given
//
//

Given(/^the user is not member of the admin user group$/, function () {
    // default behaviour
});

Given(/^the user is member of the admin user group$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.promoteAccountToAdmin(testUser.username)
    })
});

Given(/^the user has an internal admin nexus account$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.isCesAdmin(testUser.username).then(function (isAdmin) {
            if (isAdmin) {
                // create internal nexus acccount
                cy.login(testUser.username, testUser.password)
                cy.logout()
            } else {
                // promote -> create internal nexus acccount -> demote
                cy.promoteAccountToAdmin(testUser.username)
                cy.login(testUser.username, testUser.password)
                cy.logout()
                cy.demoteAccountToDefault(testUser.username)
            }
        })
    })
});

Given(/^the user has an internal default nexus account$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.isCesAdmin(testUser.username).then(function (isAdmin) {
            if (isAdmin) {
                // demote -> create internal nexus acccount -> promote
                cy.demoteAccountToDefault(testUser.username)
                cy.login(testUser.username, testUser.password)
                cy.logout()
                cy.promoteAccountToAdmin(testUser.username)
            } else {
                // create internal nexus acccount
                cy.login(testUser.username, testUser.password)
                cy.logout()
            }
        })
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
