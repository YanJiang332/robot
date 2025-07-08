***Settings***
Resource         ../resources/common_keywords.robot
Resource         ../resources/interface_status_keywords.robot
Variables        ../variables/config_loader.py
Test Teardown    Close All Connections

***Test Cases***
Interface Status Health Check
    [Documentation]    Performs status and error checks on specified interfaces for all devices.
    Set Log Level    WARN
    # Prepare commands for concurrent interface status checks
    &{commands_map_per_device}=    Create Dictionary
    ${device_ips}=    Create List    @{FRR_DEVICES.keys()}
    FOR    ${ip}    IN    @{device_ips}
        ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]
        # Only include devices that have interfaces defined for health checks
        ${interface_count}=    Get Length    ${device['health_checks']['interfaces']}
        IF    ${interface_count} > 0
            ${commands_map_per_device}[${device['ip']}] =    Create Dictionary    show_interface_brief=show interface brief
        END
    END

    ${devices_for_checks}=    Create List    @{FRR_DEVICES.values()}
    ${check_results}=    Perform Concurrent Device Checks    ${devices_for_checks}    ${commands_map_per_device}

    # Process results from concurrent checks
    @{FAILED_INTERFACES_DEVICES}=    Create List
    FOR    ${ip}    ${result}    IN    &{check_results}
        IF    '${result['status']}' == 'FAIL'
            Log    <p style="color:red;"><b>Interface Check Failed for ${ip}:</b> ${result['message']}</p>    html=True
            Append To List    ${FAILED_INTERFACES_DEVICES}    ${ip}
        ELSE IF    '${result['status']}' == 'SKIPPED'
            Log    <p style="color:orange;"><b>Interface Check Skipped for ${ip}:</b> ${result['message']}</p>    html=True
        ELSE
            Log    <p style="color:blue;">--- Running Interface Checks on ${ip} ---</p>    html=True
            ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]    # Get the full device info including health_checks
            ${interface_brief_output}=    Set Variable    ${result['command_outputs']['show_interface_brief']['output']}

            FOR    ${interface}    IN    @{device['health_checks']['interfaces']}
                Run Keyword And Continue On Failure    Check Interface Status    ${interface['name']}    ${interface['errors_threshold']}    ${interface_brief_output}
            END
        END
    END
    Set Log Level    INFO