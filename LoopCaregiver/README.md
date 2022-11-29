#  Caregiver App

## Clone Repo

* Xcode version 14 or greater required
* The Caregiver app is a fork of the LoopWorkspace repo. Follow these steps to clone the fork.
* Run the following command to clone the repo to a new directory named "LoopCaregiver" (The directory will be created for you)
```
git clone --branch=caregiver --recurse-submodules https://github.com/gestrich/LoopWorkspace LoopCaregiver

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
