***Settings***
Resource         ../resources/common_keywords.robot
Variables        ../variables/config_loader.py
Library          OperatingSystem
Library          String
Library          DateTime

***Test Cases***
Collect FRR Running Configuration
    [Documentation]    Connects to FRR routers, collects their running configurations, and provides a summary of any failures.
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${CURRENT_COLLECTION_DIR}=    Set Variable    ${CURDIR}/../collected_configs/frr_configs_${timestamp}
    Create Directory    ${CURRENT_COLLECTION_DIR}
    @{FAILED_HOSTS}=    Create List

    Set Log Level    WARN
    ${devices_for_collection}=    Create List    @{FRR_DEVICES.values()}
    ${devices_for_collection}=    Create List    @{FRR_DEVICES.values()}
    ${collection_results}=    Perform Concurrent FRR Config Collection    ${devices_for_collection}    ${GLOBAL_COMMANDS}    ${CURRENT_COLLECTION_DIR}
    Set Log Level    INFO

    # Process results from concurrent collection
    FOR    ${ip}    ${result}    IN    &{collection_results}
        IF    '${result['status']}' == 'FAIL'
            Log    <p style="color:red;"><b>Collection Failed for ${ip}:</b> ${result['message']}</p>    html=True
            Append To List    ${FAILED_HOSTS}    ${ip}
        END
    END

    ${failed_count}=    Get Length    ${FAILED_HOSTS}
    IF    ${failed_count} > 0
        ${failed_string}=    Catenate    SEPARATOR=,     @{FAILED_HOSTS}
        Fail    ${failed_count} device(s) failed to login or collect config: ${failed_string}
    END


