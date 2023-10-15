#!/bin/bash

set -e
set -u

#From https://www.bluelabellabs.com/blog/generate-apple-certificates-provisioning-profiles/

APP_NAME=LoopCaregiver
TEAM_ID="5K844XFC6W"
BUNDLE_ID="com.$TEAM_ID.loopkit.LoopCaregiver"
WORKSPACE_NAME="LoopCaregiver"
SCHEME_NAME="LoopCaregiver"
DISTRIBUTION_GROUP="Collaborators"

PROVISIONING_PROFILE_NAME="Apple Development" #How does this work when you have multiple extensions that use different provisioning profiles?
CODE_SIGNING_IDENTITY="Apple Development"
CODE_SIGNING_STYLE="Automatic"

RESULT_PATH="/Users/bill/dev/personal/loop/archives/$APP_NAME"
ARCHIVE_PATH="$RESULT_PATH/build.xcarchive"
EXPORT_PATH="$RESULT_PATH/adhocexport"
EXPORT_OPTIONS_PATH="$RESULT_PATH/exportOptions.plist"
EXPORT_METHOD="ad-hoc"
UPLOAD_SYMBOLS=false

function archive(){
  rm -rf "$RESULT_PATH" 
  mkdir "$RESULT_PATH"
  DERIVED_DATA_PATH="$RESULT_PATH/derived_data"
  RESULT_BUNDLE_PATH="$RESULT_PATH/resultbundle.xcresult"
  xcodebuild archive \
    -workspace ${WORKSPACE_NAME}.xcworkspace \
    -scheme ${SCHEME_NAME} \
    -destination generic/platform=iOS \
    -archivePath $ARCHIVE_PATH \
    -derivedDataPath $DERIVED_DATA_PATH \
    -resultBundleVersion 3 \
    -resultBundlePath $RESULT_BUNDLE_PATH \
    -IDEPostProgressNotifications=YES \
    CODE_SIGN_IDENTITY="$CODE_SIGNING_IDENTITY" \
    AD_HOC_CODE_SIGNING_ALLOWED=YES \
    CODE_SIGN_STYLE=$CODE_SIGNING_STYLE \
    DEVELOPMENT_TEAM=$TEAM_ID \
    COMPILER_INDEX_STORE_ENABLE=NO \
    -hideShellScriptEnvironment \
    -configuration Release
}

function exportAll(){
  # Create exportOptions.plist
cat > "$EXPORT_OPTIONS_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
        <key>compileBitcode</key>
        <false/>
        <key>teamID</key>
        <string>${TEAM_ID}</string>
        <key>method</key>
        <string>${EXPORT_METHOD}</string>
        <key>uploadSymbols</key>
        <${UPLOAD_SYMBOLS}/>
        <key>provisioningProfiles</key>
        <dict>
          <key>${BUNDLE_ID}</key>
          <string>${PROVISIONING_PROFILE_NAME}</string>
        </dict>
</dict>
</plist>
EOF
  xcodebuild -exportArchive \
    -archivePath $ARCHIVE_PATH \
    -exportPath $EXPORT_PATH \
    -exportOptionsPlist "$EXPORT_OPTIONS_PATH" \
    -allowProvisioningUpdates
}

function appCenterUploads {
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  "../LoopRepoManagement/app-center-upload.sh" uploadIPA "${EXPORT_PATH}/${APP_NAME}.ipa" $APP_NAME "$DISTRIBUTION_GROUP"
  "../LoopRepoManagement/app-center-upload.sh" uploadSymbols "${ARCHIVE_PATH}/dSYMs" $APP_NAME
}

function runAll(){
  archive
  exportAll
  appCenterUploads
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

