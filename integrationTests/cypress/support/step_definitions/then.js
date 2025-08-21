const {
    Then
} = require("@badeball/cypress-cucumber-preprocessor");


Then(/^the user can see administration icon$/, function () {
    cy.get('a[href="#admin/repository]').should('be.visible')
});

Then(/^the user cannot see administration icon$/, function () {
    cy.get('a[href="#admin/repository]').should('not.be.visible')
});

Then(/^the user can access scripts api$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.nexusRequestScriptingApi(testUser.username, testUser.password).then((response) => {
            expect(response.status).to.eq(200)
        });
    })
});

Then(/^the user cannot access scripts api (403)$/, function () {
    cy.fixture("testuser_data").then(function (testUser) {
        cy.nexusRequestScriptingApi(testUser.username, testUser.password).then((response) => {
            expect(response.status).to.eq(403)
        });
    })
});
