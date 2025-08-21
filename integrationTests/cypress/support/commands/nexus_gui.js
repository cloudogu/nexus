/**
 * Checks if the setup popup exists. If exists, finishes the setup process.
 */
const fullyLoadPageAndClosePopups = () => {
    cy.reload(true)
    cy.contains("User signed in", {timeout: 10000}).should("be.visible");

    cy.get("body").then(body => {
        if (body.children("div[role='presentation'].x-css-shadow").length > 0){
            cy.get("span").contains("Next").click();
            cy.get("span").contains("Next").click();
            cy.get("span").contains("Agree").click({force: true});
            cy.wait(1000)
            cy.get("span").contains("Finish").click();
        }
    });

};

Cypress.Commands.add("fullyLoadPageAndClosePopups", fullyLoadPageAndClosePopups);
