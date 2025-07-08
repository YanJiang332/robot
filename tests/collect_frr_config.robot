***Settings***
Library    SSHLibrary
Library    DateTime
Library    OperatingSystem

***Settings***
Library    SSHLibrary
Library    DateTime
Library    OperatingSystem
Variables    ../variables/frr_devices.py

***Variables***
${FRR_USERNAME}    admin
${FRR_PASSWORD}    Admin@123

***Test Cases***
Collect FRR Running Configuration
    [Documentation]    Connects to FRR routers and collects their running configurations.
    ${timestamp}=    Get Current Date    result_format=%Y%m%d_%H%M%S
    ${CURRENT_COLLECTION_DIR}=    Set Variable    ${CURDIR}/../collected_configs/frr_configs_${timestamp}
    Create Directory    ${CURRENT_COLLECTION_DIR}

    FOR    ${host}    IN    @{FRR_HOSTS}
        Log To Console    Connecting to FRR router: ${host}
        Open Connection    ${host}
        Login    ${FRR_USERNAME}    ${FRR_PASSWORD}

        ${output}=    Execute Command    show running-config    return_stdout=True
        ${output_file}=    Set Variable    ${CURRENT_COLLECTION_DIR}/frr_config_${host}.txt
        Create File    ${output_file}    ${output}
        Log To Console    FRR configuration for ${host} saved to: ${output_file}

        Close Connection
        Log To Console    Disconnected from ${host}
    END
