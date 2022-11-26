#  Caregiver App

## Workspace Clone

* Xcode version 14 or greater required
* The Caregiver app is a fork of the LoopWorkspace repo. It is recommended to keep the project separate from your Loop repo, following these steps.
* Run the following command to clone the repo to a new directory named "LoopCaregiver" (The directory will be created for you)
    * git clone --branch=caregiver --recurse-submodules https://github.com/gestrich/LoopWorkspace LoopCaregiver
* Open the workspace in Xcode
* Select the "LoopCaregiver" project on the left
* Select Signing and Capabilities and select your "team", like you would for Loop
* Select the LoopCaregiver target up top and selected your iPhone
* Build + Run

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
