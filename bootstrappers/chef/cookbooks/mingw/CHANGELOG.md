# mingw Cookbook CHANGELOG

This file is used to list changes made in each version of the mingw cookbook.

## 4.0.3 - *2024-05-02*

## 4.0.2 - *2024-05-02*

## 4.0.1 - *2023-11-06*

## 4.0.0 - *2023-11-01*

- Updated minimum Chef infra-client version supported, dropping `< 15.3`
  - Added flag unified_mode with value: true

## 3.0.1 - *2023-10-31*

- Fix metadata

## 3.0.0 - *2023-10-31*

- Adopt cookbook.
  - This is still in a broken state given we haven't updated the cookbook to use the new seven_zip cookbook.

## 2.1.9 - *2023-10-03*

## 2.1.8 - *2023-07-10*

## 2.1.7 - *2023-06-01*

## 2.1.6 - *2023-04-01*

## 2.1.5 - *2023-03-03*

## 2.1.4 - *2022-02-08*

- Remove delivery folder

## 2.1.3 - *2021-08-31*

- Standardise files with files in sous-chefs/repo-management

## 2.1.1 (2020-06-02)

- Resolve cookstyle 5.8 warnings - [@tas50](https://github.com/tas50)
- Require Chef 12.15+ - [@tas50](https://github.com/tas50)
- Fix compatibility with Chef Infra Client 16 - [@xorimabot](https://github.com/xorimabot)
  - resolved cookstyle error: resources/get.rb:26:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: resources/msys2_package.rb:31:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`
  - resolved cookstyle error: resources/tdm_gcc.rb:26:1 warning: `ChefDeprecations/ResourceUsesOnlyResourceName`

## 2.1.0 (2018-07-24)

- refactor msys2 package source and checksum to attributes

## 2.0.2 (2018-02-15)

- Remove kind_of usage in the custom resources (FC117)

## 2.0.1 (2017-04-26)

- Test with Local Delivery instead of Rake
- Add chef_version to the metadata
- Use standardize Apache 2 license string

## 2.0.0 (2017-02-27)

- Require Chef 12.5 and remove compat_resource dependency

## 1.2.5 (2017-01-18)

- Require a working compat_resource

## v1.2.4 (2016-07-26)

- New msys2 shells do not inherit PATH from windows. Provide a way for
  clients to do this.

## v1.2.3 (2016-07-25)

- If PKG_CONFIG_PATH is already defined, honor it in the msys2 shell.

## v1.2.2 (2016-06-24)

- Download msys2 from the primary download url (instead of a specific mirror).

## v1.2.1 (2016-06-23)

- Fix msys2 initial install/upgrade steps that dependended on file modification time.
- Make msys2_package :install idempotent - it should not reinstall packages.
- Do not allow bash.exe to be called if MSYSTEM is undefined.

## v1.2.0 (2016-06-03)

- Updating to fix the issue where msys2 bash does not inherit the cwd correctly

## v1.1.0 (2016-06-03)

- Add msys2 based compiler support using the new msys2_package resource

## v1.0.0 (2016-05-11)

- Remove unnecessary default_action from the resources
- Depend on compat_resource cookbook to add Chef 12.1 - 12.4 compatbility
- Add this changelog file
- Fix license metadata in metadata.rb
- Disable FC016 check
