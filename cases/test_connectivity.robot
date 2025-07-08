***Settings***
Resource         ../resources/common_keywords.robot
Variables        ../variables/config_loader.py
Test Teardown    Close All Connections

***Test Cases***
Device Connectivity Check
    [Documentation]    Checks reachability and credentials for all devices in the config.
    ...    This test will not stop on the first failure.
    @{FAILED_DEVICES}=    Create List

    Set Log Level    WARN
    # Prepare commands for concurrent connectivity check
    &{commands_map_per_device}=    Create Dictionary
    ${device_ips}=    Create List    @{FRR_DEVICES.keys()}
    FOR    ${ip}    IN    @{device_ips}
        ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]
        ${commands_map_per_device}[${device['ip']}] =    Create Dictionary    check_conn=echo Connected
    END

    ${devices_for_checks}=    Create List    @{FRR_DEVICES.values()}
    ${check_results}=    Perform Concurrent Device Checks    ${devices_for_checks}    ${commands_map_per_device}

    # Process results from concurrent checks
    FOR    ${ip}    ${result}    IN    &{check_results}
        IF    '${result['status']}' == 'FAIL'
            Log    <p style="color:red;"><b>FAILURE:</b> ${ip} - ${result['message']}</p>    html=True
            Append To List    ${FAILED_DEVICES}    ${ip}
        ELSE
            Log    <p style="color:green;"><b>SUCCESS:</b> ${ip}</p>    html=True
            # No need to Close Connection here, as it's handled by ConcurrentSSH library
        END
    END
    Set Log Level    INFO

    ${failed_count}=    Get Length    ${FAILED_DEVICES}
    IF    ${failed_count} > 0
        ${failed_string}=    Catenate    SEPARATOR=,     @{FAILED_DEVICES}
        Fail    ${failed_count} device(s) failed connectivity check: ${failed_string}
    END
