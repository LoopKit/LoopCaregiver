# Using GitHub Actions + FastLane to deploy to TestFlight

These instructions allow you to build LoopCaregiver without having access to a Mac.

* You can install LoopCaregiver on phones via TestFlight that are not connected to your computer
* You can send builds and updates to those you care for
* You can install LoopCaregiver on your phone using only the TestFlight app if a phone was lost or the app is accidentally deleted
* You do not need to worry about specific Xcode/Mac versions for a given iOS

## Introduction

The setup steps are somewhat involved, but nearly all are one time steps. Subsequent builds are trivial. Your app must be updated once every 90 days, but it's a simple click to make a new build and can be done from anywhere. The 90-day update is a TestFlight requirement.

There are more detailed instructions in LoopDocs for using GitHub for Browser Builds of LoopCaregiver and Loop, including troubleshooting and build errors. Please refer to:

* [LoopDocs: GitHub Other Apps](https://loopkit.github.io/loopdocs/gh-actions/gh-other-apps/)
* [LoopDocs: GitHub Overview](https://loopkit.github.io/loopdocs/gh-actions/gh-overview/)
* [LoopDocs: GitHub Errors](https://loopkit.github.io/loopdocs/gh-actions/gh-errors/)

Note that installing with TestFlight, (in the US), requires the Apple ID account holder to be 13 years or older. For younger Loopers, an adult must log into Media & Purchase on the child's phone to install LoopCaregiver. More details on this can be found in [LoopDocs](https://loopkit.github.io/loopdocs/gh-actions/gh-deploy/#install-testflight-loop-for-child).

## Prerequisites

* A [GitHub account](https://github.com/signup). The free level comes with plenty of storage and free compute time to build loop, multiple times a day, if you wanted to.
* A paid [Apple Developer account](https://developer.apple.com).
* Some time. Set aside a couple of hours to perform the setup.

## Save 6 Secrets

You require 6 Secrets (alphanumeric items) to use the GitHub build method, and if you use the GitHub method to build more than LoopCaregiver, e.g., Loop or Loop Follow, you will use the same 6 Secrets for each app you build with this method. Each secret is identified below by `ALL_CAPITAL_LETTER_NAMES`.

* Four Secrets are from your Apple Account
* Two Secrets are from your GitHub account
* Be sure to save the 6 Secrets in a text file using a text editor
    - Do **NOT** use a smart editor, which might auto-correct and change case, because these Secrets are case sensitive

## Generate App Store Connect API Key

This step is common for all GitHub Browser Builds; do this step only once. You will be saving 4 Secrets from your Apple Account in this step.

1. Sign in to the [Apple developer portal page](https://developer.apple.com/account/resources/certificates/list).
1. Copy the Team ID from the upper right of the screen. Record this as your `TEAMID`.
1. Go to the [App Store Connect](https://appstoreconnect.apple.com/access/api) interface, click the "Keys" tab, and create a new key with "Admin" access. Give it the name: "FastLane API Key".
1. Record the issuer id; this will be used for `FASTLANE_ISSUER_ID`.
1. Record the key id; this will be used for `FASTLANE_KEY_ID`.
1. Download the API key itself, and open it in a text editor. The contents of this file will be used for `FASTLANE_KEY`. Copy the full text, including the "-----BEGIN PRIVATE KEY-----" and "-----END PRIVATE KEY-----" lines.

## Create GitHub Personal Access Token

This step is common for all GitHub Browser Builds; do this step only once. This is the first of two GitHub secrets needed for your build.

1. Create a [new personal access token](https://github.com/settings/tokens/new):
    * Enter a name for your token, use "FastLane Access Token".
    * Change the Expiration selection to `No expiration`.
    * Select the `workflow` permission scope - this also selects `repo` scope.
    * Click "Generate token".
    * Copy the token and record it. It will be used below as `GH_PAT`.

## Make up a Password

This step is common for all GitHub Browser Builds; do this step only once. This is the second of two GitHub secrets needed for your build.

The first time you build with the GitHub Browser Build method for any DIY app, you will make up a password and record it as `MATCH_PASSWORD`. Note, if you later lose `MATCH_PASSWORD`, you will need to delete the Match-Secrets repository so that a new one can be created for you.

## Setup GitHub LoopCaregiver Repository

1. Fork https://github.com/LoopKit/LoopCaregiver into your account.
1. In the forked LoopCaregiver repo, go to Settings -> Secrets and variables -> Actions.
1. For each of the following secrets, tap on "New repository secret", then add the name of the secret, along with the value you recorded for it:
    * `TEAMID`
    * `FASTLANE_ISSUER_ID`
    * `FASTLANE_KEY_ID`
    * `FASTLANE_KEY`
    * `GH_PAT`
    * `MATCH_PASSWORD`

## Validate repository secrets

This step validates most of your six Secrets and provides error messages if it detects an issue with one or more.

1. Click on the "Actions" tab of your LoopCaregiver repository and enable workflows if needed
1. On the left side, select "1. Validate Secrets".
1. On the right side, click "Run Workflow", and tap the green `Run workflow` button.
1. Wait, and within a minute or two you should see a green checkmark indicating the workflow succeeded.
1. The workflow will check if the required secrets are added and that they are correctly formatted. If errors are detected, please check the run log for details.

## Add Identifiers for LoopCaregiver App

1. Click on the "Actions" tab of your LoopCaregiver repository.
1. On the left side, select "2. Add Identifiers".
1. On the right side, click "Run Workflow", and tap the green `Run workflow` button.
1. Wait, and within a minute or two you should see a green checkmark indicating the workflow succeeded.

## Create App Group

If you have already built LoopCaregiver via Xcode using this Apple ID, you can skip on to [Add App Group to Bundle Identifiers](#add-app-group-to-bundle-identifiers).

1. Go to [Register an App Group](https://developer.apple.com/account/resources/identifiers/applicationGroup/add/) on the apple developer site.
1. For Description, use "LoopCargiver App Group".
1. For Identifier, enter "group.com.TEAMID.loopkit.LoopCaregiverGroup", subsituting your team id for `TEAMID`.
1. Click "Continue" and then "Register".

## Add App Group to Bundle Identifiers

Note 1 - If you previously built with Xcode, the `Names` listed below may be different, but the `Identifiers` will match. A table is provided below the steps to assist. The Add Identifier Action that you completed above generates these 5 identifiers.

Note 2 - Depending on your build history, you may find some of the Identifiers are already configured - and you are just verifying the status; but in other cases, you will need to configure the Identifiers.

1. Go to [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) on the apple developer site.
1. For each of the following identifier names: 
    * LoopCaregiver
    * LoopCaregiverWidgetExtension
    * LoopCaregiverIntentExtension
    * LoopCaregiverWatch
    * LoopCaregiverWatchWidgetExtension
1. Click on the identifier's name.
1. On the "App Groups" capabilies, click on the "Configure" button.
1. Select the "LoopCaregiver App Group"
1. Click "Continue".
1. Click "Save".
1. Click "Confirm".
1. Remember to do this for each of the identifiers above.

#### Table with Name and Identifiers for LoopCaregiver

| NAME | IDENTIFIER |
|-------|------------|
| LoopCaregiver | com.TEAMID.loopkit.LoopCaregiver |
| LoopCaregiverWidgetExtension | com.TEAMID.loopkit.LoopCaregiver.WidgetExtension |
| LoopCaregiverIntentExtension | com.TEAMID.loopkit.LoopCaregiver.IntentExtension |
| LoopCaregiverWatch | com.TEAMID.loopkit.LoopCaregiver.watchkitapp |
| LoopCaregiverWatchWidgetExtension | com.TEAMID.loopkit.LoopCaregiver.watchkitapp.WidgetExtension |

## Create LoopCaregiver App in App Store Connect

If you have created a LoopCaregiver app in App Store Connect before, you can skip this section.

1. Go to the [apps list](https://appstoreconnect.apple.com/apps) on App Store Connect and click the blue "plus" icon to create a New App.
    * Select "iOS".
    * Select a name: this will have to be unique, so you may have to try a few different names here, but it will not be the name you see on your phone, so it's not that important.
    * Select your primary language.
    * Choose the bundle ID that matches `com.TEAMID.loopkit.LoopCaregiver`, with TEAMID matching your team id.
    * SKU can be anything; e.g. "123".
    * Select "Full Access".
1. Click Create

You do not need to fill out the next form. That is for submitting to the app store.

## Create Building Certificates

1. Go back to the "Actions" tab of your LoopCaregiver repository in GitHub.
1. On the left side, select "3. Create Certificates".
1. On the right side, click "Run Workflow", and tap the green `Run workflow` button.
1. Wait, and within a minute or two you should see a green checkmark indicating the workflow succeeded.

## Build LoopCaregiver

1. Click on the "Actions" tab of your LoopCaregiver repository.
1. On the left side, select "4. Build LoopCaregiver".
1. On the right side, click "Run Workflow", and tap the green `Run workflow` button.
1. You have some time now. Go enjoy a coffee. The build should take about 10-20 minutes.
1. Your app should eventually appear on [App Store Connect](https://appstoreconnect.apple.com/apps).
1. For each phone/person you would like to support LoopCaregiver on:
    * Add them in [Users and Access](https://appstoreconnect.apple.com/access/users) on App Store Connect.
    * Add them to your TestFlight Internal Testing group.

## TestFlight and Deployment Details

Please refer to [LoopDocs: Set Up Users](https://loopkit.github.io/loopdocs/gh-actions/gh-first-time/#set-up-users-and-access-testflight) and [LoopDocs: Deploy](https://loopkit.github.io/loopdocs/gh-actions/gh-deploy/)

## App Group Update

The Caregiver app was updated in November 2023 to require App Groups for iOS widget support. You need to take some extra steps the first time you build since the update. Select each link and follow the steps to complete the update.

1. [Add Identifiers for LoopCaregiver App](#add-identifiers-for-loopcaregiver-app)
1. [Create App Group](#create-app-group)
1. [Add App Group to Bundle Identifiers](#add-app-group-to-bundle-identifiers)
1. [Create Building Certificates](#create-building-certificates)
1. [Build LoopCaregiver](#build-loopcaregiver)

## Build Errors

### App Group Capability Missing

This error means the app identifiers in the Apple Developer portal are missing the app group capability. To resolve:

1. Perform the [App Group Update](#app-group-update) steps.
1. Pay close attention to the "Add App Group to Bundle Identifiers" as this error suggests at least one of your app identifiers is missing the LoopCaregiver App Group.

### Match Repository Missing

This error indicates the Match-Secrets repository is missing or was deleted. To resolve: 

1. [Validate repository secrets](#validate-repository-secrets). This will create the Match-Secrets repository.
1. [Add Identifiers for LoopCaregiver App](#add-identifiers-for-loopcaregiver-app)
1. [Create Building Certificates](#create-building-certificates)
1. [Build LoopCaregiver](#build-loopcaregiver)

### Credentials Invalid

This is often a temporary issue that can be resolved by:

* Run [Create Building Certificates](#create-building-certificates) again.

If that fails, there is likely an issue with one of your saved secrets. Check that you set the following secrets correctly. See [Setup GitHub LoopCaregiver Repository](#Setup-GitHub-LoopCaregiver-Repository).

* FASTLANE_ISSUER_ID
* FASTLANE_KEY_ID
* FASTLANE_KEY
* GH_PAT

### Match-Secrets Repository Clone Issue

This is often a temporary issue that can be resolved by:

* Run [Create Building Certificates](#create-building-certificates) again.

If that fails, there is likely an issue with one of your saved secrets. Try these steps:

1. Check your Github Personal Access Token has the correct permissions. See [Create GitHub Personal Access Token](create-github-personal-access-token)
1. Check that the Github Personal Access Token (GH_PAT) was stored as a secret. See the secret setup steps in [Setup GitHub LoopCaregiver Repository](setup-gitHub-loopcaregiver-repository)

### Missing Bundle Identifier

This error indicates you are missing some required bundle identifier(s).

In November 2023, existing Caregiver builds require a 1 time update. Perform the [App Group Update](#app-group-update) steps if not completed yet.

If those steps were already completed, instead try the following:

1. [Add Identifiers for LoopCaregiver App](#add-identifiers-for-loopcaregiver-app)
1. [Create Building Certificates](#create-building-certificates)

### Bundle Identifier Missing App Group

This error indicates one or more of your App Identifiers are not assigned the "LoopCaregiver App Group". To resolve:

1. Create the Caregiver app group if not previously done. Follow the steps [Create App Group](#create-app-group).
1. Add the app group for each bundle identifier. Follow the steps in [Add App Group to Bundle Identifiers](#Add-App-Group-to-Bundle-Identifiers)
1. [Create Building Certificates](#create-building-certificates)
1. [Build LoopCaregiver](#build-loopcaregiver)

### Certificate is Missing

This error indicates your Apple Certificate is missing. To resolve:

1. Delete the Github Match-Secrets repository.
1. [Validate repository secrets](#validate-repository-secrets). This will create the Match-Secrets repository.
1. [Add Identifiers for LoopCaregiver App](#add-identifiers-for-loopcaregiver-app)
1. [Create Building Certificates](#create-building-certificates)
1. [Build LoopCaregiver](#build-loopcaregiver)

### Maximum Certificates Reached

This error indicates you have too many certificates on the Apple developer portal. This sometimes occurs after deleting and recreating your Match Secrets repository. To resolve:

1. Login to the Apple developer portal. 
1. Go to the "Certificates" page. 
1. Delete all "Distribution" certificates that contain "API Key" in the "Created By" column.

### Provisioning Profiles Invalid

This error indicates a provisioning profile(s) is invalid. To resolve:

1. [Add Identifiers for LoopCaregiver App](#add-identifiers-for-loopcaregiver-app)
1. [Create Building Certificates](#create-building-certificates)

### Missing Signing Certificates

The error indicates a provisioning profile is missing its signing certificate. To resolve: 

* [Create Building Certificates](#create-building-certificates)
