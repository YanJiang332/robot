***Settings***
Library    String

***Keywords***
Check Interface Status
    [Documentation]    Checks a specific interface's status using 'show interface brief' output.
    [Arguments]    ${interface_name}    ${errors_threshold}    ${command_output}
    
    # Check if interface is 'up' in the brief output
    Should Match Regexp    ${command_output}    (?m)^${interface_name} +up.*$    msg=Interface ${interface_name} is not in UP state.