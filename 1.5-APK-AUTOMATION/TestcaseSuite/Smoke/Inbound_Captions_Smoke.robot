*** Settings ***
Resource    ../../PageObject/keywords/CommonKeywords.resource
Resource    ../../PageObject/keywords/TestLifecycle.resource
Suite Setup    Suite Setup
Suite Teardown    Suite Teardown
Test Setup    TMCC 11239 Test Setup
Test Teardown    TMCC 11239 Test Teardown

*** Test Cases ***
Scenario: VoIP - Receive inbound call and verify captions
    [Tags]    inbound_captions_smoke    smoke
    [Documentation]    Quick inbound + captions check for new device (DID ${DID_1}).
    Given the user is on the Home screen
    And Get Callee Number From Home Screen
    When an inbound call is placed to the Assisted User
    And the Assisted User answers the call
    Then the call should connect successfully
    And captions should be displayed during the call
    And the user ends the call
