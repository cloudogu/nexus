/**
 * Reloads the page and finishes the onboarding wizard if Nexus shows it.
 */
const fullyLoadPageAndClosePopups = () => {
    cy.reload(true)
    cy.get('[data-analytics-id="nxrm-header-user-menu"]', {timeout: 30000}).should("exist");

    // the wizard mounts after the header, so it is not there yet when the header appears
    cy.wait(2000)

    cy.get("body").then(body => {
        if (body.find('[data-testid="onboarding-wizard__root"]').length === 0) {
            return
        }
        cy.get('[data-testid="onboarding-wizard__action"]').click(); // Get Started
        cy.get('[data-testid="onboarding-wizard__action"]').click(); // Next
        // the EULA has to be accepted before the wizard lets us finish
        cy.get('[data-testid="eula-step__accept-checkbox"]').click();
        cy.get('[data-testid="onboarding-wizard__action"]').click(); // Finish
        cy.get('[data-testid="onboarding-wizard__root"]').should("not.exist");
    });

};

Cypress.Commands.add("fullyLoadPageAndClosePopups", fullyLoadPageAndClosePopups);
