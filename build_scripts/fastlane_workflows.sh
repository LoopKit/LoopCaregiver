#!/bin/bash

set -euo pipefail

function extractMatchFromLineUsingRegex() {
    local regex=$1
    local line=$2

    if [[ "$line" =~ $regex ]]; then
        error_line="${BASH_REMATCH[1]}"
        echo "$error_line"
    fi
}

function getErrorLinesFromFileUsingRegex() {
    local filePath="$1"
    local regex="$2"
    while read -r line; do
        error="$(extractMatchFromLineUsingRegex "$regex" "$line")"
        if [[ -n "$error" ]]; then
            echo "$error"
        fi
    done <"$filePath"
}

function getErrorLinesFromFile() {
    local filePath="$1"
    errors=""

    if [[ -z "$errors" ]]; then
        errors="$(getErrorLinesFromFileUsingRegex "$filePath" ".*[Ee]rror: (.*)")"
    fi

    if [[ -z "$errors" ]]; then
        errors="$(getErrorLinesFromFileUsingRegex "$filePath" "\[!](.*)")"
    fi

    if [[ -n "$errors" ]]; then
        echo "$errors"
    fi
}

function missingAppGroupMessage() {
    #NOTE: When running the caregiver_build lane, and lacking the added app group (but having the capability), I got this message.
    #So I went onto the apple portal and added the group.
    #That invalidated the profiles. I then ran the caregiver_build lane again. The regenerated the profiles...
    #Is the Create Certs step unneeded in this scenario? How about when the app group capabilty is missing?
    appGroup="group.com.$TEAMID.loopkit.LoopCaregiverGroup"
    echo "::error::The Caregiver app group is not added to the identifer in the below error message. Login to the Apple dev portal to add $appGroup. Then run the Create Certificates Github workflow. See the Loop Docs for more information."
}

function caregiver_identifier() {
    
    if ! fastlane caregiver_identifier 2>1 | tee fastlane.log; then
        errors="$( getErrorLinesFromFile fastlane.log )"

        if [[ -n "$errors" ]]; then
            echo "$errors" | while read -r line; do
                echo "::error::$line"
            done
        fi
        exit 1
    fi
}

function create_certs() {

    if ! fastlane caregiver_cert 2>1 | tee fastlane.log; then

        #errors="$( getErrorLinesFromFile fastlane.log )"
        #echo "$errors" | while read -r line; do
        while read -r line; do
            if [[ "$line" == *"capability not found for identifier"* ]]; then
                #Ex: Error: APP_GROUPS capability not found for identifier: com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverIntentExtension
                #This error match is a custom error we throw from fastlane
                #Without this, the certificate step will succeeed with
                #invalid certifiates.
                #The user will then fail in the build stage and need to add
                #the capabilty, then rerun the 'Create Certificates' step.
                echo "$(missingAppGroupMessage)"
            elif [[ "$line" =~ Couldn\'t\ find\ bundle\ identifier\ \'([^\']+)\' ]]; then
                #Could not find App ID with bundle identifier 'com.5K844XFC6W.loopkit.LoopCaregiver.LoopCaregiverWidgetExtension'
                captured_id="${BASH_REMATCH[1]}"
                echo "::error::Action Required: Login to the Apple developer portal to add the following app identifier: '${captured_id}'. Then re-run the 'Add Identifiers' and 'Create Certificates' workflows."
            elif [[ "$line" == *"App Identifier not found for"* ]]; then
              echo "::error::The app identifier in the below error message has not been created. Run the Add Identifiers Gitbub Workflow. Then add the app group to the identifier. See the Loop Docs for more information."
            #else
                #echo "::error::$line"
            fi
        done <fastlane.log
        exit 1
    fi
}

function build_loopcaregiver() {

    if ! fastlane caregiver_build 2>1 | tee fastlane.log; then
        errors="$( getErrorLinesFromFile fastlane.log )"

        if [[ -n "$errors" ]]; then
            echo "$errors" | while read -r line; do

                if [[ "$line" == *"No matching provisioning profiles found for"* ]]; then
                    #I think this is the error when your provisioing profiles are missing.
                    echo "::error::Provisioning profile(s) invalid. Run the the following Github workflows to add them: 2. Add Identifiers 3. Create Certificates"
                elif [[ "$line" == *"doesn't match the entitlements file's value for the com.apple.security.application-groups entitlement"* ]]; then
                    #Occurs when you have the wrong App Group assigned or the group value is empty
                    #but the group capablity is added.
                    echo "$(missingAppGroupMessage)"
                elif [[ "$line" == *"doesn't support the App Groups capability"* ]]; then
                    #This error was hit when I removed the App Group capability from the identifier
                    #Adding it to the group and running just the Build step resolved it.
                    echo "$(missingAppGroupMessage)"
                elif [[ "$line" == *"doesn't include the com.apple.security.application-groups entitlement"* ]]; then
                    #This error was hit when I removed the App Group capability from the identifier
                    #Adding it to the group and running just the Build step resolved it.
                    echo "$(missingAppGroupMessage)"
                fi

                echo "::error::$line"
            done
        else
            echo "::error::View the build log for details."
        fi

        exit 1
    fi
}


function caregiver_release() {

    if ! fastlane caregiver_release 2>1 | tee fastlane.log; then
        errors="$( getErrorLinesFromFile fastlane.log )"

        if [[ -n "$errors" ]]; then
            echo "$errors" | while read -r line; do
                echo "::error::$line"
            done
        fi
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
