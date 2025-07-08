***Settings***
Library    String

***Keywords***
Check Default Route Exists
    [Documentation]    Checks if a default route (0.0.0.0/0) exists in the routing table using 'show ip route' output.
    [Arguments]    ${command_output}
    # Example line for a static default route: S>* 0.0.0.0/0 [1/0] via 10.0.2.2, eth0
    Should Match Regexp    ${command_output}    (K|O|S)>\\* 0\.0\.0\.0/0    msg=Default route 0.0.0.0/0 not found or not active!