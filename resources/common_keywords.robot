***Settings***
Library    SSHLibrary
Library    Collections
Library    ConcurrentSSH

***Keywords***
Attempt Login To Device
    [Documentation]    Attempts to connect and log in to a single device.
    ...    Returns a status and an error message if any.
    [Arguments]    ${device}
    ${host}=    Set Variable    ${device['ip']}
    Log To Console    Attempting to connect to ${host}

    ${conn_status}    ${conn_error}=    Run Keyword And Ignore Error    Open Connection    ${host}
    IF    '${conn_status}' == 'FAIL'
        RETURN    FAIL    ${conn_error}
    END

    ${login_status}    ${login_error}=    Run Keyword And Ignore Error    Login    ${device['username']}    ${FRR_PASSWORDS_MAP}[${device['ip']}]    log_level=NONE
    IF    '${login_status}' == 'FAIL'
        Close Connection
        RETURN    FAIL    "Login failed for user ${device['username']}"
    END

    Log To Console    Successfully connected and logged in to ${host}
    RETURN    PASS    "Connection successful"

Connect And Handle Login Failure
    [Documentation]    Attempts to log in to a device and fails the test if login is unsuccessful.
    [Arguments]    ${device}
    ${status}    ${error_msg}=    Attempt Login To Device    ${device}
    IF    '${status}' != 'PASS'
        Fail    Could not log in to ${device['ip']}: ${error_msg}
    END

Perform Concurrent FRR Config Collection
    [Documentation]    Performs concurrent FRR configuration collection on multiple devices.
    ...    Returns a dictionary of results for each device.
    [Arguments]    ${devices_list}    ${commands_list}    ${base_collection_dir}    ${max_workers}=5
    ${results}=    Run Concurrent Collection    ${devices_list}    ${FRR_PASSWORDS_MAP}    ${commands_list}    ${base_collection_dir}    ${max_workers}
    RETURN    ${results}

Perform Concurrent Device Checks
    [Documentation]    Performs concurrent checks on multiple devices.
    ...    Returns a dictionary of results for each device, including command outputs.
    [Arguments]    ${devices_list}    ${commands_map_per_device}    ${max_workers}=5
    ${results}=    Run Concurrent Checks    ${devices_list}    ${FRR_PASSWORDS_MAP}    ${commands_map_per_device}    ${max_workers}
    RETURN    ${results}

Execute Commands And Validate Output
    [Documentation]    Executes a list of commands and performs basic validation on the output.
    [Arguments]    @{commands}
    ${outputs_list}=    Create List
    FOR    ${command}    IN    @{commands}
        Log To Console    Executing command: ${command}
        ${output}=    Execute Command    ${command}    return_stdout=True
        ${header}=    Set Variable    --- Command: ${command} ---

        # Basic validation for common error strings
        ${has_error}=    Evaluate    """${output}""".__contains__("% Invalid") or """${output}""".__contains__("Error:")
        IF    ${has_error}
            Log    <p style="color:orange;"><b>Warning:</b> Command may have failed. Output contains error-like string.</p>    html=True
            ${list_item}=    Set Variable    ${header}\n!!! WARNING: Possible error in output !!!\n${output}
        ELSE
            ${list_item}=    Set Variable    ${header}\n${output}
        END
        Append To List    ${outputs_list}    ${list_item}
    END
    ${all_outputs}=    Catenate    SEPARATOR=\n\n    @{outputs_list}
    RETURN    ${all_outputs}