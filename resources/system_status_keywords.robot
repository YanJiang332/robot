***Settings***
Library    String
Library    OperatingSystem

***Keywords***
Check CPU Utilization
    [Documentation]    Checks if CPU utilization is below a given threshold using vtysh.
    [Arguments]    ${threshold}
    ${output}=    Execute Command    show system-cpu
    # Example output: CPU usage: 1.5%
    ${cpu_usage_str}=    Get Regexp Matches    ${output}    CPU usage: (\d+\.?\d*)%    1
    IF    not ${cpu_usage_str}
        Fail    Could not extract CPU usage from 'show system-cpu' output.
    END
    ${cpu_usage}=    Convert To Number    ${cpu_usage_str[0]}
    Log    CPU Usage: ${cpu_usage}%
    Should Be True    ${cpu_usage} < ${threshold}    msg=CPU usage ${cpu_usage}% exceeds threshold of ${threshold}%

Check Memory Utilization
    [Documentation]    Checks if Memory utilization is below a given threshold using 'show system-memory' output.
    [Arguments]    ${threshold}    ${command_output}
    # Example output: Total: 7961MB, Free: 7264MB, Used: 697MB (8.7%)
    ${mem_usage_str}=    Get Regexp Matches    ${command_output}    Used: .*?(\\d+\\.?\\d*)%\\)    1
    IF    not ${mem_usage_str}
        Fail    Could not extract memory usage from 'show system-memory' output.
    END
    ${mem_usage_percent}=    Convert To Number    ${mem_usage_str[0]}
    Log    Memory Usage: ${mem_usage_percent}%
    Should Be True    ${mem_usage_percent} < ${threshold}    msg=Memory usage ${mem_usage_percent}% exceeds threshold of ${threshold}%