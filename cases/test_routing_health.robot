***Settings***
Resource         ../resources/common_keywords.robot
Resource         ../resources/routing_keywords.robot
Variables        ../variables/config_loader.py
Test Teardown    Close All Connections

***Test Cases***
Routing Health Check
    [Documentation]    Performs routing health checks on all applicable devices.
    Set Log Level    WARN
    # Prepare commands for concurrent routing checks
    &{commands_map_per_device}=    Create Dictionary
    ${device_ips}=    Create List    @{FRR_DEVICES.keys()}
    FOR    ${ip}    IN    @{device_ips}
        ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]
        # Only include devices that require default route check
        IF    '${device['health_checks']['routing']['must_have_default_route']}' == 'True'
            ${commands_map_per_device}[${device['ip']}] =    Create Dictionary    show_ip_route=show ip route
        END
    END

    ${devices_for_checks}=    Create List    @{FRR_DEVICES.values()}
    ${check_results}=    Perform Concurrent Device Checks    ${devices_for_checks}    ${commands_map_per_device}

    # Process results from concurrent checks
    @{FAILED_ROUTING_DEVICES}=    Create List
    FOR    ${ip}    ${result}    IN    &{check_results}
        IF    '${result['status']}' == 'FAIL'
            Log    <p style="color:red;"><b>Routing Check Failed for ${ip}:</b> ${result['message']}</p>    html=True
            Append To List    ${FAILED_ROUTING_DEVICES}    ${ip}
        ELSE IF    '${result['status']}' == 'SKIPPED'
            Log    <p style="color:orange;"><b>Routing Check Skipped for ${ip}:</b> ${result['message']}</p>    html=True
        ELSE
            Log    <p style="color:blue;">--- Running Routing Checks on ${ip} ---</p>    html=True
            ${ip_route_output}=    Set Variable    ${result['command_outputs']['show_ip_route']['output']}
            Run Keyword And Continue On Failure    Check Default Route Exists    ${ip_route_output}
        END
    END
    Set Log Level    INFO

    ${failed_count}=    Get Length    ${FAILED_ROUTING_DEVICES}
    IF    ${failed_count} > 0
        ${failed_string}=    Catenate    SEPARATOR=,     @{FAILED_ROUTING_DEVICES}
        Fail    ${failed_count} device(s) failed routing health check: ${failed_string}
    END
    