#  Caregiver App


## Warning

* Loop Remote code, such as this Caregiver app, are highly experimental and may be subject to issues that could cause serious risks to one's health/life.
* The developers make no claims regarding its safety and do not recommend anyone use experimental code. You take full responsibility for running this code and do so at your own risk.
* The Loop community's forums should be closely monitored for app updates, if available.
* Bugs could cause information in the app to be incorrect or out-of-date.
* This app and Nightscout may not reflect all delivered treatments (i.e. Due to network delays or bugs). You must be aware of this to avoid delivering dangerous, duplicate treatments to Loop.
* The Nightscout QR code and API Key should be secured. Anyone with this information can remotely send treatments (bolus, carbs, etc).
* The phone with Caregiver installed should have a locking mechanism. Anyone with access to the Caregiver app can remotely send treatments (bolus, carbs, etc). If a phone is lost or stolen, the QR code in Loop's Settings should be reset.
* There may be other risks not known or mentioned here.

## Clone Repo

* Xcode version 15 or greater required
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

## Remote Commands 2.0

Remote Commands 2.0 is a set of experimental features that supports command status and helps with the limitations of push notifications. This feature is very early in development. Like all remote features in Loop and Caregiver, you are assuming the risks of using open-source DIY code.

Setting up these features may be difficult except for advanced Loop builders that are comfortable troubleshooting git and Xcode issues and deploying to Nightscout.

### Branch Configuration

Special Nightscout and Loop branches are required to use Remote 2.0. This describes each.

WARNING: These Loop and NS branch are based off dev. If dev updates are desired you will need to merge them in yourself.

* Nightscout
  * Description: Includes Remote 2.0 API and Time sensitive notifications. This was based off NS dev as of June 2023.
  * Repo: https://github.com/gestrich/cgm-remote-monitor
  * Branch: feature/2023-07/bg/remote-commands
* Loop
  * Description: Includes Remote 2.0 additions
  * Repo: https://github.com/LoopKit/LoopWorkspace.git
  * Branch: Use below to clone which was forked from the dev branch. Note these branches get out of date quickly with dev work. 
    * `git clone https://github.com/LoopKit/LoopWorkspace.git --branch=feature/2023-10/bg/remote-commands --recurse-submodules`

### Remote 2.0 Usage

* Activate Remote Commands 2 in Caregiver
  * Caregiver -> Settings
  * Tap and hold the "Disabled" text under the "Experimental Features" section to reveal the secret experimental features options.
  * Toggle the "Remote Commands 2" switch to ON
* After delivering carbs/bolus/override, the command status will show at the bottom of Caregiver Settings -> Select Loopers name.
* Additional commands such as autobolus activation, closed loop activation are available in aforementioned view.
* Note that occasionally (every few weeks) you should clear old commands in Settings -> Select Loopers name -> Delete All Commands. This is to avoid a performance issue when too many commands build up that will be fixed later.
