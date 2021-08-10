Feature: Browser-based CAS login and logout functionality

  @requires_testuser
  Scenario: ces admin user can access scripting api
    Given the user is member of the admin user group
    When the user logs into the CES
    Then the user can access scripts api

  @requires_testuser
  Scenario: default user cannot access scripting api
    Given the user is not member of the admin user group
    When the user logs into the CES
    Then the user cannot access scripts api 403

  @requires_testuser
  Scenario: internal admin user user which is not in admin group can access scripting api
    Given the user has an internal admin nexus account
    When the user is not member of the admin user group
    Then the user can access scripts api
