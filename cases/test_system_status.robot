***Settings***
Resource         ../resources/common_keywords.robot
Resource         ../resources/system_status_keywords.robot
Variables        ../variables/config_loader.py
Test Teardown    Close All Connections

***Test Cases***
***Test Cases***
System Status Health Check
    [Documentation]    Performs CPU and Memory health checks on all devices.
    Set Log Level    WARN
    # Prepare commands for concurrent system status checks
    &{commands_map_per_device}=    Create Dictionary
    ${device_ips}=    Create List    @{FRR_DEVICES.keys()}
    FOR    ${ip}    IN    @{device_ips}
        ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]
        ${commands_map_per_device}[${device['ip']}] =    Create Dictionary    show_system_cpu=show system-cpu    show_system_memory=show system-memory
    END

    ${devices_for_checks}=    Create List    @{FRR_DEVICES.values()}
    ${check_results}=    Perform Concurrent Device Checks    ${devices_for_checks}    ${commands_map_per_device}

    # Process results from concurrent checks
    @{FAILED_SYSTEM_DEVICES}=    Create List
    FOR    ${ip}    ${result}    IN    &{check_results}
        IF    '${result['status']}' == 'FAIL'
            Log    <p style="color:red;"><b>System Check Failed for ${ip}:</b> ${result['message']}</p>    html=True
            Append To List    ${FAILED_SYSTEM_DEVICES}    ${ip}
        ELSE IF    '${result['status']}' == 'SKIPPED'
            Log    <p style="color:orange;"><b>System Check Skipped for ${ip}:</b> ${result['message']}</p>    html=True
        ELSE
            Log    <p style="color:blue;">--- Running System Status Checks on ${ip} ---</p>    html=True
            ${device}=    Set Variable    ${FRR_DEVICES}[${ip}]    # Get the full device info including health_checks
            ${cpu_output}=    Set Variable    ${result['command_outputs']['show_system_cpu']['output']}
            ${mem_output}=    Set Variable    ${result['command_outputs']['show_system_memory']['output']}

            Run Keyword And Continue On Failure    Check CPU Utilization    ${device['health_checks']['cpu_threshold']}    ${cpu_output}
            Run Keyword And Continue On Failure    Check Memory Utilization    ${device['health_checks']['memory_threshold']}    ${mem_output}
        END
    END
    Set Log Level    INFO

    ${failed_count}=    Get Length    ${FAILED_SYSTEM_DEVICES}
    IF    ${failed_count} > 0
        ${failed_string}=    Catenate    SEPARATOR=,     @{FAILED_SYSTEM_DEVICES}
        Fail    ${failed_count} device(s) failed system status check: ${failed_string}