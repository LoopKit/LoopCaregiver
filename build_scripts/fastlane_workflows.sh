#!/bin/bash

set -euo pipefail

function appGroupName() {
    echo "group.com.$TEAMID.loopkit.LoopCaregiverGroup"
}

function missingCertificateError() {
    #This error is hit after deleting the match repo. The Create secrets step will recreate it (or is it after deleting your certificate???)
    #Running Add Identifiers does not reveal the error nor fix it.
    echo "::error::Certificate is missing. Resolve this by recreating your Match repository. Then run all Gihub workflows again."
}

function missingMatchRepoError() {
    #This error is hit after deleting the match repo. The Validate Secrets step will recreate it.
    echo "::error::The Match-Secrets repository is missing. To resolve, run the 'Validate Secrets' step again."
}

function missingAppGroupError() {
    #NOTE: When running the caregiver_build lane, and lacking the added app group (but having the capability), I got this message.
    #So I went onto the apple portal and added the group.
    #That invalidated the profiles. I then ran the caregiver_build lane again. The regenerated the profiles...
    #Is the Create Certs step unneeded in this scenario? How about when the app group capabilty is missing?
    appGroup="group.com.$TEAMID.loopkit.LoopCaregiverGroup"
    echo "::error::The Caregiver app group is not added to the identifer in the below error message. Login to the Apple dev portal to add $appGroup. Then run the Create Certificates Github workflow. See the Loop Docs for more information."
}

function caregiver_identifier() {
    if ! fastlane caregiver_identifier 2>1 | tee fastlane.log; then
        #Default
        echo "::error::Could not create identifiers. See error log for details."
        exit 1
    fi
}

function create_certs() {
    if ! fastlane caregiver_cert 2>1 | tee fastlane.log; then
        while read -r line; do
            if [[ "$line" == *"Error cloning certificates git repo"* ]]; then
                #Ex: Error cloning certificates git repo, please make sure you have access to the repository - see instructions above
                echo "$(missingMatchRepoError)"
                exit 1
            elif [[ "$line" == *"Error cloning certificates repo, please make sure you have read access to the repository you want to use"* ]]; then
                #Sometimes you need to run the create certificates step twice due to this error.
                #It seems there is a race condition with it being created and immediately clone... or maybe being rate limited.
                echo "$("::error::Error cloning Match-Secrets repo. First try running the `Create Certificates` step again. If that fails, check your Github repository access.")"
            elif [[ "$line" == *"Certificate "* && "$line" == *"(stored in your storage) is not available on the Developer Portal"* ]]; then
                #Ex: Certificate 'WZUK5NWX3L' (stored in your storage) is not available on the Developer Portal
                echo "$(missingCertificateError)"
                exit 1
            elif [[ "$line" == *"Could not create another Distribution certificate, reached the maximum number of available Distribution certificates."* ]]; then
                #Occurs if you exceed certs. This can happen if you keep add/delete the Match-Secrets repo during testing.
                echo "::error::Cannot create a new certificate. Login to the Apple developer portal and delete unneeded certificates."
                exit 1
            elif [[ "$line" == *"Couldn't find bundle identifier"* && $"line" =~ identifier\ \'([^\']+)\' ]]; then
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
            elif [[ "$line" == *"No matching provisioning profiles found for"* ]]; then
                #I think this is the error when your provisioning profiles are missing.
                #Note that deleting all your profiles does not trigger this error...?? Maybe when you have an old cert?
                echo "::error::Error 1 - Provisioning profile(s) invalid. Run the the following Github workflows to add them: 2. Add Identifiers 3. Create Certificates"
                exit 1
            elif [[ "$line" == *"doesn't support the App Groups capability"* ]]; then
                #This error was hit when I removed the App Group capability from the identifier
                #Adding it to the group and running just the Build step resolved it.
                echo "$(missingAppGroupError)"
                exit 1
            elif [[ "$line" == *"doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement"* && "$line" =~ \(in\ target\ \'([^\']+)\' ]]; then
                app_identifier="${BASH_REMATCH[1]}"
                #Missing or wrong App Group but the group capablity is added.
                #Ex: error: Provisioning profile "match AppStore com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWidgetExtension" doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement. (in target 'LoopCaregiverWidgetExtension' from project 'LoopCaregiver')[0m
                echo "::error::An app identifier is missing the required app group. Resolve this by logging into the Apple Developer portal and add the '$(appGroupName)' app group to the '${app_identifier}' identifier. Then re-run the 'Create Certificates' and 'Build Caregiver' workflows."
                exit 1
            elif [[ "$line" == *"doesn't include the com.apple.security.application-groups entitlement"* ]]; then
                #This error was hit when I removed the App Group capability from the identifier
                #Adding it to the group and running just the Build step resolved it.
                echo "$(missingAppGroupError)"
                exit 1
            fi
        done <fastlane.log
        
        #Default
        echo "::error::Error 4 Could not build Loop Caregiver. See error log for details."
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
