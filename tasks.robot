*** Settings ***
Library     RPA.Robocorp.Process
Library     RPA.Robocorp.Storage
Library     RPA.Robocorp.Vault
Library     Collections
Library     SQLiteDatabase
Library     RPA.FileSystem
Library     RPA.Excel.Files


*** Variables ***
${ASSET_RUNS_DATABASE}      Process Run Database
${ASSET_RUNS_EXCEL}         Process Run Excel
${DB_FILE}                  ${CURDIR}${/}process_runs.db
${EXCEL_FILE}               ${CURDIR}${/}process_runs.xlsx
@{PROCESSES}                @{EMPTY}


*** Tasks ***
Minimal task
    [Setup]    Task initialization
    Process list sync
    Process runs sync
    Set File Asset    ${ASSET_RUNS_DATABASE}    path=${DB_FILE}
    Set File Asset    ${ASSET_RUNS_EXCEL}    path=${EXCEL_FILE}
    Log    Done.


*** Keywords ***
Task initialization
    ${secrets}=    Get Secret    APISecrets
    Set Credentials    workspace_id=%{RC_WORKSPACE_ID}    apikey=${secrets}[apikey]

Process list sync
    ${processes}=    List Processes
    ${processes}=    Evaluate    [item for item in $processes if "name" in item.keys()]
    Set Task Variable    ${PROCESSES}    ${processes}
    TRY
        Get File Asset    Process Run Database    path=${DB_FILE}    overwrite=True
        Connect    ${DB_FILE}
        FOR    ${p}    IN    @{processes}
            ${query}=    Set Variable
            ...    REPLACE INTO processes (id, name, workspaceId) VALUES ('${p}[id]', '${p}[name]', '${p}[workspaceId]')
            Execute Query    ${query}
        END
    EXCEPT
        ${exists}=    Does File Exist    ${DB_FILE}
        IF    ${exists}
            Connect    ${DB_FILE}
            FOR    ${p}    IN    @{processes}
                ${query}=    Set Variable
                ...    REPLACE INTO processes (id, name, workspaceId) VALUES ('${p}[id]', '${p}[name]', '${p}[workspaceId]')
                Execute Query    ${query}
            END
        ELSE
            Create Process Runs Database    ${DB_FILE}
            FOR    ${p}    IN    @{processes}
                ${query}=    Set Variable
                ...    INSERT INTO processes (id, name, workspaceId) VALUES ('${p}[id]', '${p}[name]', '${p}[workspaceId]')
                Execute Query    ${query}
            END
        END
    END

Process runs sync
    Remove File    ${EXCEL_FILE}
    Create Workbook    ${EXCEL_FILE}
    &{run_entry}=    Create Dictionary
    ...    process_name=${EMPTY}
    ...    process_id=${EMPTY}
    ...    process_run_id=${EMPTY}
    ...    runNo=${EMPTY}
    ...    result=${EMPTY}
    ...    state=${EMPTY}
    ...    duration=${EMPTY}
    ...    startTs=${EMPTY}
    ...    endTs=${EMPTY}
    Connect    ${DB_FILE}
    FOR    ${p}    IN    @{PROCESSES}
        ${runs}=    List Process Runs    process_id=${p}[id]    limit=99999
        ${runs}=    Evaluate    sorted($runs, key=lambda k: k['runNo'], reverse=True)
        FOR    ${r}    IN    @{runs}
            IF    "endTs" in $r.keys()
                ${endTs}=    Set Variable    ${r}[endTs]
            ELSE
                ${endTs}=    Set Variable    ${NONE}
            END
            Set To Dictionary    ${run_entry}
            ...    process_name=${p}[name]
            ...    process_id=${p}[id]
            ...    process_run_id=${r}[id]
            ...    runNo=${r}[runNo]
            ...    result=${r}[result]
            ...    state=${r}[state]
            ...    duration=${r}[duration]
            ...    startTs=${r}[startTs]
            ...    endTs=${endTs}
            Append Rows To Worksheet    ${run_entry}    header=True
            ${query}=    Set Variable
            ...    REPLACE INTO process_runs (process_id, process_run_id, runNo, result, state, duration, startTs, endTs) VALUES ('${p}[id]', '${r}[id]', ${r}[runNo], '${r}[result]', '${r}[state]', ${r}[duration], '${r}[startTs]', '${endTs}')
            Execute Query    ${query}
        END
    END
    Save Workbook
