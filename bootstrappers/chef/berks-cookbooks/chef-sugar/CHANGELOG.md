# Chef Sugar Changelog

This file is used to list changes made in each version of the chef-sugar cookbook and gem.

## v5.0.0 (2018-12-26)

- BREAKING CHANGE: Require Chef 13 or later
- Trim out test files and the cookbook from the gem artifact to slim install size

## v4.2.1 (2018-12-06)

- Repackaged with an older stove to remove the metadata.rb on the Supermarket for older chef-client releases

## v4.2.0 (2018-12-05)

- Added a new parallels? helper
- Added support for the Raspberry Pi 1 and Zero to armhf? helper
- Added a centos_final? helper

## v4.1.0 (2018-08-16)

- Improve the detection of linux hosts with the linux? helper. Amazon Linux and obscure distros will now be properly detected.

## v4.0.1 (2018-08-09)

- Add new Debian, Mint, macOS codenames
- Add new Ubuntu codenames: artful, bionic, cosmic

## v4.0.0 (2018-01-26)

- Require Ruby 2.2 or later and Chef 12.10 or later
- Cookbook now installs the chef-sugar gem via a metadata installation so chef-sugar::default on your runlist is no longer needed
- Added additional metadata to the cookbook: supports, issue_url, source_url, chef_version.
- Requirements improved in the readme

## v3.6.0 (2017-10-26)

- Add Ubuntu zesty and debian stretch detection
- Add softlayer? helper
- Add aarch64? helper

## v3.5.0 (2016-07-12)

- Improve the systemd check to not fail on older kernels or Windows hosts
- Add detection of macOS 10.11 and 10.12

## v3.4.0 (2016-07-18)

### Improvements

- Add `virtual?` and `physical?` methods
- Add Scaleway C1 server (arm arch) support
- Add IMB s390x support
- Add missing Ubuntu release names

### Bug Fixes

- Drop Ruby 2.0.0 support from Travis test matrix
- Pin to Rack 1.6 (dev dep)

## v3.3.0 (2016-01-11)

### Improvements

- Break up `Chef::Sugar::Constraints` into a class and a dsl file
- Add `platform_version` method with full constraints comparison support

## v3.2.0 (2015-12-10)

### Improvements

- Add platform matchers for `debian` and `fedora`
- Add `openvz` support under virtualization
- Add init system detection support
- Add support for `nexus`, `ios_xr` platforms and `wrlinux` platform_family
- Add additional `aix` helpers

### Bug Fixes

- Properly expose `Architecture#i386?` in the DSL

## v3.1.1 (2015-06-23)

### Improvements

- Update Intel CPU types based on existing Fauxhai data
- Update SPARC logic and 32/64-bit logic for x86 and i386

### Bug Fixes

- Fix 32-bit logic
- Fix default behavior to include chef-sugar at compile time
- Fix Chef 12.1.0 warnings for chef_gem compile time install
- Fix `redhat_enterprise_linux?` matcher

## v3.0.2 (2015-03-26)

### Improvements

- Add helpers for `ppc64` and `ppc64le` architecture

### Bug Fixes

- Adjustments to error message

## v3.0.1 (2015-03-20)

### Breaking Changes

- Rename `compile_time` `to at_compile_time` - if your recipes are affected by this breaking change, your Chef Client run will produce a verbose error message with details on how to fix the error.

## v3.0.0 (2015-03-17)

### Breaking Changes

- Drop support for Ruby 1.9 (it might still work, but it is no longer officially supported)

### Improvements

- Remove accidentially committed gem source
- Bump development dependencies
- Add `digitalocean?` matcher
- Expose the `rhel` platform as `el`
- Add `ppc64le` platform
- Add helper for determining if architecture is SPARC
- Add helper for determining if architecture is Intel
- Add dynamic platform/version matchers for Solaris

### Bug Fixes

- Reset namespace_options when reaching top-level resources

## v2.5.0 (2015-01-05)

### Improvements

- Add `data_bag_item_for_environment` function
- Add `kvm?` matcher
- Add `virtualbox?` matcher

### Bug Fixes

- Use `.key?` to check for hash key presence, raising an `AttributeDoesNotExist` error sooner

## v2.4.1 (2014-10-12)

- No changes from v2.4.0 - forced a new version upload to the Chef Supermarket

## v2.4.0 (2014-10-12)

### Improvements

- Add `docker?` matcher

## v2.3.2 (2014-10-07)

### Big Fixues

- Include `amd64` in `_64_bit?` check

## v2.3.1 (2014-10-07)

### Improvements

- Check all 64-bit architectures that may be reported by Ohai

### Bug Fixes

- Be more tolerant of `nil` values return from sub functions
- Check to make sure `node['domain']` is not `nil` before calling `#include?`

## v2.3.0 (2014-09-24)

### Improvements

- Add `vmware?` matcher
- Allow the attribute DSL to access parent attributes

### Bug Fixes

- Return `true` or `false` from all Boolean methods (instead of `nil` or truthy values)

## v2.2.0 (2014-08-20)

### Improvements

- Add `smartos?` matcher
- Add `omnios?` matcher

## v2.1.0 (2014-06-26)

### Improvements

- Add `solaris2?` matcher
- Add `aix?` matcher
- Add 'lxc?' matcher

### Bug Fixes

- Fix a bug in namespace memoization during attribute initialization

## v2.0.0 (2014-06-16)

### Breaking

- Remove `not_linux?` method
- Remove `not_windows?` method

### Improvements

- Miscellaneous spelling fixes
- Update a failing unit test for `installed?`
- Add Mac OS X to the list of platforms (Yosemite)
- Upgrade to RSpec 3
- Fix `which` (and `installed?` and `installed_at_version?`) when given an absolute path
- Fix `linux?` check to only return true on real linuxes

## v1.3.0 (2014-05-05)

- Check both `$stdout` and `$stderr` in `version_for`
- Add additional platform versions
- Make `includes_recipe?` a top-level API (instead of just Node)
- Match on the highest version number instead of direct equality checking on platform versions
- Define `Object#blank?` as a core extension
- Define `String#flush` as a core extension
- Remove Stove

## v1.2.6 (2014-03-16)

- Fix a bug in `vagrant?` returning false on newer Vagrant versions
- Remove Coveralls

## v1.2.4 (2014-03-13)

- See (1.2.2), but I botched the release

## v1.2.2 (2014-03-13)

- Fix a critical bug with `encrypted_data_bag_item` using the wrong key

## v1.2.0 (2014-03-09)

- Add `namespace` functionality for specifying attributes in a DSL
- Add constraints helpers for comparing version strings
- Add `require_chef_gem` to safely require and degrade if a gem is not installed
- Add `deep_fetch` and `deep_fetch!` to fetch deeply nested keys
- Accept an optional secret key in `encrypted_data_bag_item` helper and raise a helpful error if one is not set (NOTE: this changes the airity of the method, but it's backward-compatible because Ruby is magic)
- Add Stove for releasing
- Updated copyrights for 2014

## v1.1.0 (2013-12-10)

- Add `cloudstack?` helper
- Add data bag helpers
- Remove foodcritic checks
- Upgrade development gem versions
- Randomize spec order

## v1.0.1 (2013-10-15)

- Add development recipe
- Add `compile_time`, `before`, and `after` filters

## v1.0.0 (2013-10-15)

- First public release
