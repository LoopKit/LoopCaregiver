#!/bin/bash

set -euo pipefail

function appGroupName() {
    echo "group.com.$TEAMID.loopkit.LoopCaregiverGroup"
}

function missingCertificateError() {
    #Occurs after deleting your certificate. No steps seem to fix this, except deleting the Match-Secrets repo.
    echo "::error::Certificate is missing. Resolve this by deleting the Github Match-Secrets repository. Then run all Gihub workflows again."
}

function missingMatchRepoError() {
    #Occurs after deleting the match repo. The Validate Secrets step will recreate it.
    echo "::error::The Match-Secrets repository is missing. To resolve, run the 'Validate Secrets' step again."
}

function readMEURL() {
    branchName=${GITHUB_HEAD_REF:-${GITHUB_REF#refs/heads/}}
    echo "${REPO_URL}/blob/${branchName}/fastlane/testflight.md"
}

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
            if [[ "$line" == *"Error cloning certificates git repo"* ]]; then
                #Ex: Error cloning certificates git repo, please make sure you have access to the repository - see instructions above
                echo "::error title=Match Repository Missing::$(missingMatchRepoError) For more details on this error: $(readMEURL)/#match-repository-missing"
                echo "::error title=Fastlane Details::$line"
                exit 1
            elif [[ "$line" == *"Error cloning certificates repo, please make sure you have read access to the repository you want to use"* ]]; then
                #Sometimes you need to run the create certificates step twice due to this error.
                #It seems there is a race condition with it being created and immediately clone... or maybe being rate limited.
                echo "::error title=Match Repository Clone Issue::Error cloning Match-Secrets repo. First try running the `Create Certificates` step again. If that fails, check your Github repository access. For more details on this error: $(readMEURL)/#match-repository-clone-issue"
                echo "::error title=Fastlane Details::$line"
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                echo "$(missingCertificateError)"
                exit 1
            elif [[ "$line" == *"Could not create another Distribution certificate, reached the maximum number of available Distribution certificates."* ]]; then
                #Occurs if you exceed certs. This can happen if you keep add/delete the Match-Secrets repo during testing.
                echo "::error::Cannot create a new certificate. Login to the Apple developer portal and delete unneeded certificates."
                exit 1
            elif [[ "$line" == *"Couldn't find bundle identifier"* && "$line" =~ identifier\ \'([^\']+)\' ]]; then
                #Ex: Couldn't find bundle identifier 'com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverIntentExtension' for the user ''
                captured_id="${BASH_REMATCH[1]}"
                echo "::error::The app identifier '${captured_id}' is missing from the Apple Developer portal. Resolve this by re-running the 'Add Identifiers' and 'Create Certificates' workflows."
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
                echo "$(missingMatchRepoError)"
                exit 1
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                echo "$(missingCertificateError)"
                exit 1
            #TODO: I have not seen this one for a while - delete this case if I can't reproduce after trying an upgrade.
            elif [[ "$line" == *"No matching provisioning profiles found for"* ]]; then
                #I think this is the error when your provisioning profiles are missing.
                #Note that deleting all your profiles does not trigger this error...?? Maybe when you have an old cert?
                echo "::error::Provisioning profile(s) invalid. Run the the 'Add Identifiers' and 'Create Certificates' workflows."
                exit 1
            elif [[ "$line" == *"doesn't support the App Groups capability"*  && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #Replicate this error by removing the App Group capability from the identifier
                #Adding the capability and group, then running the Build step resolves it.
                app_identifier="${BASH_REMATCH[1]}"
                echo "::error title=App Group Capability Missing::Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group (where *** is your 10-character TEAMID) to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows. For more details on this error: $(readMEURL)/#App-Group-Capability-Missing"
                echo "::error title=Fastlane Details::$line"
                exit 1
            elif [[ "$line" == *"doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement"* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                app_identifier="${BASH_REMATCH[1]}"
                #Missing or wrong App Group but the group capablity is added.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWidgetExtension" doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement. (in target 'LoopCaregiverWidgetExtension' from project 'LoopCaregiver')[0m
                echo "::error title=Bundle Identifier Missing App Group:: An bundle identifier is missing the required app group. Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows. For more details on this error: $(readMEURL)/#bundle-identifier-missing-app-group"
                echo "::error title=Fastlane Details::$line"
                exit 1
            elif [[ "$line" == *"doesn't include signing certificate "* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                #This can happen if you delete the Match repo and skip the `Create Certificates` step.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWatchApp" doesn't include signing certificate "Apple Distribution: William Gestrich (5K844XFC6W)". (in target 'LoopCaregiverWatchApp' from project 'LoopCaregiver')
                app_identifier="${BASH_REMATCH[1]}"
                echo "::error::The provisioning profile for $app_identifier is out-of-date. To resolve, run the 'Create Certificates' workflow again."
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Could not build Loop Caregiver. See error log for details."
        exit 1
    fi
}

function caregiver_release() {
    if ! fastlane caregiver_release 2>1 | tee fastlane.log; then
        #Default
        echo "::error::Could not create release. See error log for details."
        exit 1
    fi
}

# Check if the function exists
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
