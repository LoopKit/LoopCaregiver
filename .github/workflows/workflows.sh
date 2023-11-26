#!/bin/bash

set -eu
set -o errexit
set -o pipefail
set -o nounset

## Workflows

# Unused except for local testing.
function create_identifier() {
    if ! fastlane caregiver_identifier 2>1 | tee fastlane.log; then
        echo "::error::Could not create identifiers. See error log for details."
        exit 1
    fi
}

# Unused except for local testing.
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
                # There may be a race condition between creating the repo and immediately cloning it.
                # Note the Validate / Access job may catch this first.
                readMeSectionTitle="Match-Secrets Repository Clone Issue"
                errorMessage="There was an error cloning the Match-Secrets repository. First try running the `Create Certificates` step again. If that fails, check your Github repository access."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Authentication credentials are missing or invalid."* ]]; then
                # Ex: Authentication credentials are missing or invalid. - Provide a properly configured and signed bearer token, and make sure that it has not expired. Learn more about Generating Tokens for API Requests https://developer.apple.com/go/?id=api-generating-tokens
                readMeSectionTitle="Credentials Invalid"
                errorMessage="There was an error with your credentials. First try running the `Create Certificates` step again. If that fails, check the following secrets FASTLANE_ISSUER_ID, FASTLANE_KEY_ID, FASTLANE_KEY, and GH_PAT."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                logMissingCertificateError "$1"
                exit 1
            elif [[ "$line" == *"Could not create another Distribution certificate, reached the maximum number of available Distribution certificates."* ]]; then
                #Occurs if you exceed certs. This can happen if you keep add/delete the Match-Secrets repo during testing.
                readMeSectionTitle="Maximum Certificates Reached"
                errorMessage="Cannot create a new certificate. Login to the Apple developer portal and delete unneeded certificates."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Couldn't find bundle identifier"* && "$line" =~ identifier\ \'([^\']+)\' ]]; then
                #Ex: Couldn't find bundle identifier 'com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverIntentExtension' for the user ''
                captured_id="${BASH_REMATCH[1]}"
                readMeSectionTitle="Missing Bundle Identifier"
                errorMessage="The app identifier '${captured_id}' is missing from the Apple Developer portal. Resolve this by re-running the 'Add Identifiers' and 'Create Certificates' workflows."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Could not create certificates. See error log for details."
        exit 1
    fi
}

function build() {
    if ! fastlane caregiver_build 2>1 | tee fastlane.log; then
        while read -r line; do
            if [[ "$line" == *"Error cloning certificates git repo"* ]]; then
                # Ex: Error cloning certificates git repo, please make sure you have access to the repository - see instructions above
                # Occurs after deleting the match repo. The Validate Secrets step will recreate it.
                # Note the Validate / Access job may catch this first.
                readMeSectionTitle="Match Repository Missing"
                errorMessage="The Match-Secrets repository is missing. To resolve, run the 'Validate Secrets' step again."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                logMissingCertificateError "$1"
                exit 1
            #TODO: I have not seen this one for a while - delete this case if I can't reproduce after trying an upgrade.
            elif [[ "$line" == *"No matching provisioning profiles found for"* ]]; then
                readMeSectionTitle="Provisioning Profiles Invalid"
                errorMessage="Provisioning profile(s) are invalid. Run the the 'Add Identifiers' and 'Create Certificates' workflows."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't support the App Groups capability"*  && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #Replicate this error by removing the App Group capability from the identifier
                app_identifier="${BASH_REMATCH[1]}"
                readMeSectionTitle="App Group Capability Missing"
                errorMessage="Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group (where *** is your 10-character TEAMID) to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement"* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                app_identifier="${BASH_REMATCH[1]}"
                #Missing or wrong App Group but the group capablity is added.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWidgetExtension" doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement. (in target 'LoopCaregiverWidgetExtension' from project 'LoopCaregiver')[0m
                readMeSectionTitle="Bundle Identifier Missing App Group"
                errorMessage="A bundle identifier is missing the required app group. Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group (where *** is your 10-character TEAMID) to the '${app_identifier}' identifier. Add this app group to the app identifiers. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            elif [[ "$line" == *"doesn't include signing certificate "* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #This can happen if you delete the Match repo and skip the `Create Certificates` step.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWatchApp" doesn't include signing certificate "Apple Distribution: William Gestrich (5K844XFC6W)". (in target 'LoopCaregiverWatchApp' from project 'LoopCaregiver')
                app_identifier="${BASH_REMATCH[1]}"
                readMeSectionTitle="Missing Signing Certificates"
                errorMessage="The provisioning profile for $app_identifier is missing its signing certificate. To resolve, run the 'Create Certificates' workflow again."
                logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Could not build Loop Caregiver. See error log for details."
        exit 1
    fi
}

# Unused except for local testing.
function release() {
    if ! fastlane caregiver_release 2>1 | tee fastlane.log; then
        #Default
        echo "::error::Could not create release. See error log for details."
        exit 1
    fi
}

## Environment Helpers

function appGroupName() {
    echo "group.com.$TEAMID.loopkit.LoopCaregiverGroup"
}

## Error Message Helpers

function logMissingCertificateError() {
    #Occurs after deleting your certificate. No steps seem to fix this, except deleting the Match-Secrets repo.
    line="$1"
    readMeSectionTitle="Certificate is Missing"
    errorMessage="Certificate is missing from the Apple developer portal. Resolve this by deleting the Github Match-Secrets repository. Then run all Gihub workflows again."
    logErrorMessages "${readMeSectionTitle}" "${errorMessage}" "${line}"
}

function logErrorMessages() {
    readMeSectionTitle="$1"
    errorMessage="$2"
    rawError="$3"
    readMeID="$(echo $readMeSectionTitle | tr " " "-")"
    branchName=${GITHUB_HEAD_REF:-${GITHUB_REF#refs/heads/}}
    readMEURL="${REPO_URL}/blob/${branchName}/fastlane/testflight.md"
    echo "::error title=$readMeSectionTitle::$errorMessage For more details on this error: ${readMEURL}/#${readMeID}"
    echo "::error title=Fastlane Details::$rawError"
}

## Invoke any script function from the command line

if [ $# -gt 0 ]; then
  "$@"
else
  # Show a helpful error
  echo "Functions Available:"
  typeset -f | awk '!/^main[ (]/ && /^[^ {}]+ *\(\)/ { gsub(/[()]/, "", $1); print $1}'
  exit 1
fi
