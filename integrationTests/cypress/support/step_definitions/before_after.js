const {
    Before,
    After
} = require("cypress-cucumber-preprocessor/steps");

/**
 * Create a testuser which has no admin rights to perform user operations
 */
Before({tags: "@requires_testuser"}, () => {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.usermgtTryDeleteUser(testUser.username)
        cy.nexusDeleteUserViaApi(testUser.username)
        cy.log("Creating test user")
        cy.usermgtCreateUser(testUser.username, testUser.givenname, testUser.surname, testUser.displayName, testUser.mail, testUser.password)
    })
});

/**
 * Deletes the created testuser after every scenario
 */
After({tags: "@requires_testuser"}, () => {
    cy.logout();

    cy.fixture("testuser_data").then(function (testUser) {
        cy.log("Removing test user")
        cy.usermgtDeleteUser(testUser.username)
        cy.nexusDeleteUserViaApi(testUser.username)
    })
});
