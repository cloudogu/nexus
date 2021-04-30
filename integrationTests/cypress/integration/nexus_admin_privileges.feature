Feature: Browser-based CAS login and logout functionality

  @requires_testuser
  Scenario: ces user with admin privileges has admin privileges in nexus
    Given the user is member of the admin user group
    When the user logs into the dogu
    Then the user can see administration icon

  @requires_testuser
  Scenario: ces user without admin privileges has no admin privileges in nexus
    Given the user is not member of the admin user group
    When the user logs into the dogu
    Then the user cannot see administration icon

  @requires_testuser
  Scenario: internal nexus admin account is demoted after login of non admin
    Given the user has an internal admin nexus account
    And the user is not member of the admin user group
    When the user logs into the dogu
    Then the user cannot see administration icon

  @requires_testuser
  Scenario: internal nexus default account is promoted after login of admin
    Given the user has an internal default nexus account
    And the user is member of the admin user group
    When the user logs into the dogu
    Then the user can see administration icon

  @requires_testuser
  Scenario: ces admin user can access scripting api
    Given the user is member of the admin user group
    When the user logs into the dogu
    Then the user can access scripts api

  @requires_testuser
  Scenario: default user cannot access scripting api
    Given the user is not member of the admin user group
    When the user logs into the dogu
    Then the user cannot access scripts api 403

  @requires_testuser
  Scenario: internal admin user user which is not in admin group can access scripting api
    Given the user has an internal admin nexus account
    When the user is not member of the admin user group
    Then the user can access scripts api

#  @requires_testuser
#  Scenario: internal default user in admin group cannot access scripting api
#    Given the user has an internal default nexus account
#    When the user is not member of the admin user group
#    Then the user cannot access scripts api 403
