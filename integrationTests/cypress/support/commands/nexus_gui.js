/**
 * Checks if the setup popup exists. If exists, finishes the setup process.
 */
const fullyLoadPageAndClosePopups = () => {
    cy.contains("User signed in", {timeout: 30000}).should("be.visible");

    cy.get("body").then(body => {
        if (body.children("div[role='presentation'].x-mask.x-border-box").length > 0){
            cy.get("span").contains("Next").click();
            cy.get("label").contains("No, not interested.").click();
            cy.get("span").contains("Next").click({force: true});
            cy.get("span").contains("Finish").click();
        }
    });

};

Cypress.Commands.add("fullyLoadPageAndClosePopups", fullyLoadPageAndClosePopups);
