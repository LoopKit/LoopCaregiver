#  Caregiver App

## Clone Repo

* Xcode version 14 or greater required
* Run the following command to clone the repo to a new directory named "LoopCaregiver" (The directory will be created for you)
```
git clone --branch=dev --recurse-submodules https://github.com/LoopKit/LoopCaregiver LoopCaregiver

```
* Open the workspace in Xcode
   * Continue in your current terminal with these commands
```
cd LoopCaregiver
xed .

```
* Select the "LoopCaregiver" project on the left
* Select Signing and Capabilities and select your "team", like you would for Loop
* Select the LoopCaregiver target up top instead of Loop (Workspace) and select your iPhone
* Make sure dependencies have finished
* Build + Run

## Update Repo

* You need to update the repo to get the last bug fixes and features.
* You need to be in a terminal in the LoopCaregiver folder you created earlier and use these commands

```
git stash
git pull --recurse-submodules

```

This may show some `Fetching` lines and end in a message that includes:


`Fast-forward`

` # files changed, # insertions(+), # deletions(-)`

or

`
Already up to date.
`

In either case, to build:

```
git stash pop
xed .

```

If the `git stash pop` gives an error, you'll have to sign the targets again. If it succeeds, you can just build.


## Add Looper

* On first run, you will be prompted to link your Looper's device.
* Follow the steps to input your Looper's data and scan the QR code from the Looper's Loop app: Settings -> Services -> Nightscout


## Features

* Multiple Looper Profiles
* Remote Bolus 
* Remote Carbs
* Overrides
* OTP codes automatically sent with remote commands
* Loop Graphs

## Remote Commands 2

Remote Commands 2 is a set of features that supports remote command status and helps with the limitations of push notifications. This feature is very early in development and subject to change quickly.

Setting up these features is only suggested for advanced Loop builders that are comfortable troubleshooting git and Xcode issues and deploying to Nightscout. 

* Deploy special caregiver instance of Nightscout: https://github.com/gestrich/cgm-remote-monitor/tree/caregiver 
  * Make sure to deploy the "caregiver" branch
* Build special caregiver branch of LoopWorkspace which is based https://github.com/gestrich/LoopWorkspace/tree/caregiver
  * This branch is based on the Loop 3.0 branch (not Loop dev) + remote command additions.
  * Make sure to build the "caregiver" branch
* Activate Remote Commands 2 in Caregiver
  * Caregiver -> Settings
  * Tap and hold the "Disabled" text under the "Experimental Features" section to reveal the secret experimental features options.
  * Toggle the "Remote Commands 2" switch to ON
* After delivering carbs/bolus/override, the command status will show at the bottom of Caregiver Settings -> Select Loopers name.
* Additional commands such as autobolus activation, closed loop activation are available in aforementioned view.
