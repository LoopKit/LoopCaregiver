#!/bin/bash

set -euo pipefail

## Environment Helpers

function appGroupName() {
    echo "group.com.$TEAMID.loopkit.LoopCaregiverGroup"
}

function readMEURL() {
    branchName=${GITHUB_HEAD_REF:-${GITHUB_REF#refs/heads/}}
    echo "${REPO_URL}"
    #echo "${REPO_URL}/blob/${branchName}/fastlane/testflight.md"
}

## Error Message Helpers

function logMissingCertificateError() {
    #Occurs after deleting your certificate. No steps seem to fix this, except deleting the Match-Secrets repo.
    line="$1"
    errorTitle="Certificate is Missing"
    errorMessage="Certificate is missing from the Apple developer portal. Resolve this by deleting the Github Match-Secrets repository. Then run all Gihub workflows again."
    logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
}

function logMissingMatchRepoError() {
    #Occurs after deleting the match repo. The Validate Secrets step will recreate it.
    line="$1"
    errorTitle="Match Repository Missing"
    errorMessage="The Match-Secrets repository is missing. To resolve, run the 'Validate Secrets' step again."
    logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
}

function logErrorMessages() {
    errorTitle="$1"
    errorMessage="$2"
    rawError="$3"
    readMETag="#$(echo $errorTitle | tr " " "-")"
    echo "::error title=$errorTitle::$errorMessage For more details on this error: $(readMEURL)/${readMETag}"
    echo "::error title=Fastlane Details::$rawError"
}

## Workflows

#Unused except for local testing.
function caregiver_identifier() {
    if ! fastlane caregiver_identifier 2>1 | tee fastlane.log; then
        echo "::error::Could not create identifiers. See error log for details."
        exit 1
    fi
}

#Unused except for local testing.
function validate_secrets() {
    if ! fastlane validate_secrets 2>1 | tee fastlane.log; then
        echo "::error::Could not validate secrets. See error log for details."
        exit 1
    fi
}

function create_certs() {
    
    if ! fastlane caregiver_cert 2>1 | tee fastlane.log; then
        while read -r line; do
            if [[ "$line" == *"Error cloning certificates repo, please make sure you have read access to the repository you want to use"* ]]; then
                #Sometimes you need to run the create certificates step twice due to this error.
                #It seems there is a race condition with it being created and immediately clone... or maybe being rate limited.
                errorTitle="Match Repository Clone Issue"
                errorMessage="Error cloning Match-Secrets repo. First try running the `Create Certificates` step again. If that fails, check your Github repository access."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                logMissingCertificateError "$1"
                exit 1
            elif [[ "$line" == *"Could not create another Distribution certificate, reached the maximum number of available Distribution certificates."* ]]; then
                #Occurs if you exceed certs. This can happen if you keep add/delete the Match-Secrets repo during testing.
                errorTitle="Maximum Certificates Reached"
                errorMessage="Cannot create a new certificate. Login to the Apple developer portal and delete unneeded certificates."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Couldn't find bundle identifier"* && "$line" =~ identifier\ \'([^\']+)\' ]]; then
                #Ex: Couldn't find bundle identifier 'com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverIntentExtension' for the user ''
                captured_id="${BASH_REMATCH[1]}"
                errorTitle="Missing Bundle Identifier"
                errorMessage="The app identifier '${captured_id}' is missing from the Apple Developer portal. Resolve this by re-running the 'Add Identifiers' and 'Create Certificates' workflows."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Could not create certificates. See error log for details."
        exit 1
    fi
}

function build_loopcaregiver() {
    if ! fastlane caregiver_build 2>1 | tee fastlane.log; then
        while read -r line; do
            if [[ "$line" == *"Error cloning certificates git repo"* ]]; then
                #Ex: Error cloning certificates git repo, please make sure you have access to the repository - see instructions above
                logMissingMatchRepoError "${line}"
                exit 1
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                logMissingCertificateError "$1"
                exit 1
            #TODO: I have not seen this one for a while - delete this case if I can't reproduce after trying an upgrade.
            elif [[ "$line" == *"No matching provisioning profiles found for"* ]]; then
                #I think this is the error when your provisioning profiles are missing.
                #Note that deleting all your profiles does not trigger this error...?? Maybe when you have an old cert?
                errorTitle="Provisioning Profiles Invalid"
                errorMessage="Provisioning profile(s) are invalid. Run the the 'Add Identifiers' and 'Create Certificates' workflows."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't support the App Groups capability"*  && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #Replicate this error by removing the App Group capability from the identifier
                #Adding the capability and group, then running the Build step resolves it.
                app_identifier="${BASH_REMATCH[1]}"
                errorTitle="App Group Capability Missing"
                errorMessage="Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group (where *** is your 10-character TEAMID) to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement"* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                app_identifier="${BASH_REMATCH[1]}"
                #Missing or wrong App Group but the group capablity is added.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWidgetExtension" doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement. (in target 'LoopCaregiverWidgetExtension' from project 'LoopCaregiver')[0m
                errorTitle="Bundle Identifier Missing App Group"
                errorMessage="A bundle identifier is missing the required app group. Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group (where *** is your 10-character TEAMID) to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't include signing certificate "* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #This can happen if you delete the Match repo and skip the `Create Certificates` step.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWatchApp" doesn't include signing certificate "Apple Distribution: William Gestrich (5K844XFC6W)". (in target 'LoopCaregiverWatchApp' from project 'LoopCaregiver')
                app_identifier="${BASH_REMATCH[1]}"
                errorTitle="Missing Signing Certificates"
                errorMessage="The provisioning profile for $app_identifier is missing its signing certificate. To resolve, run the 'Create Certificates' workflow again."
                logErrorMessages "${errorTitle}" "${errorMessage}" "${line}"
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Could not build Loop Caregiver. See error log for details."
        exit 1
    fi
}

#Unused except for local testing.
function caregiver_release() {
    if ! fastlane caregiver_release 2>1 | tee fastlane.log; then
        #Default
        echo "::error::Could not create release. See error log for details."
        exit 1
    fi
}

## Invoke any script function from the command line

  if [ $# -gt 0 ]; then
#if declare -f "$1" > /dev/null
  # call arguments verbatim
  "$@"
else
  # Show a helpful error
  echo "Functions Available:"
  typeset -f | awk '!/^main[ (]/ && /^[^ {}]+ *\(\)/ { gsub(/[()]/, "", $1); print $1}'
  exit 1
fi
