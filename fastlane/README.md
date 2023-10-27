fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios caregiver_build

```sh
[bundle exec] fastlane ios caregiver_build
```

Build Caregiver

### ios caregiver_release

```sh
[bundle exec] fastlane ios caregiver_release
```

Push Caregiver to TestFlight

### ios caregiver_identifier

```sh
[bundle exec] fastlane ios caregiver_identifier
```

Provision Caregiver Identifier

### ios caregiver_cert

```sh
[bundle exec] fastlane ios caregiver_cert
```

Provision Caregiver Certificate

### ios validate_secrets

```sh
[bundle exec] fastlane ios validate_secrets
```

Validate Secrets

### ios nuke_certs

```sh
[bundle exec] fastlane ios nuke_certs
```

Nuke Certs

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
