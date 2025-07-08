*** Settings ***
Library    BuiltIn

*** Test Cases ***
Simple Addition Test
    ${result}=    Evaluate    1 + 1
    Should Be Equal As Numbers    ${result}    2


