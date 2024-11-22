# CHANGELOG for seven_zip

This file is used to list changes made in each version of seven_zip.

## 4.2.10 - *2024-05-06*

## 4.2.9 - *2023-07-10*

## 4.2.8 - *2023-05-17*

## 4.2.7 - *2023-05-04*

- Fix CI
- Update actions/stale action to v8
- Update sous-chefs/.github action to v2

## 4.2.6 - *2023-02-15*

- Update actions/stale action to v7

## 4.2.5 - *2023-02-14*

- Update actions/checkout action to v3

## 4.2.4 - *2023-02-14*

- Add renovate.json

## 4.2.3 - *2023-02-14*

- Remove Delivery

## 4.2.2 - *2021-08-31*

- Standardise files with files in sous-chefs/repo-management

## 4.2.1 - *2021-06-07*

- [CI] Change ActionsHub actions to main
- [CI] Change checkout action to v2
- [CI] Change final step to an echo for faster final step

## 4.2.0 - *2021-06-07*

- Add remove action to seven_zip_tool

## 4.1.1 - *2021-06-01*

- Update delivery configuration

## 4.1.0 - *2021-05-20*

- Reduce Chef requirement to >= 15.3

## 4.0.0 - *2021-04-29*

- Increase the supported version of Chef to Chef 16

  This is inline with our support policies, allowing us to use the newest Chef features

- Remove dependency on the deprecated Windows cookbook
- Convert to modern custom resources
- Remove the default recipe
- Remove default_spec as we no longer have a default recipe
- Use the Chef `execute` and `directory` resources rather than Ruby methods
- Pull Windows helpers from the Windows cookbook and fix them to work in this cookbook

  As the Windows cookbook is no longer maintained many of the methods we used were deprecated
  in Ruby 2.7 but were never fixed. These methods have now been removed in Ruby 3.0

- Move resource documentation to the documentation/resource directory.
- Update README to reflect new usage

## 3.2.0 - *2021-01-24*

- Sous Chefs Adoption
- Standardise files with files in sous-chefs/repo-management
- Various Cookstyle fixes
- Migrate from ServerSpec to InSpec for integration testing
- Update to 7-Zip 19.00

## 3.1.2

- Update nokogiri from [1.8.2 to 1.8.5](https://snyk.io/vuln/SNYK-RUBY-NOKOGIRI-72433)

## 3.1.1

- Fix deprecation warning regarding the use of `win_friendly_path` helper.

## 3.1.0

- Having a simple resource to setup 7-zip allows other resources (since including a recipe inside a resource is not a good pattern) to use it to ensure that their prerequisites are installed before-hand.
- This resource leverage existing attributes as default values to keep backward compatibility.
- The `seven_zip::default` recipe's code has been refactored to just use this resource.

## 3.0.0

- Support Chef 13, drop support for Chef 12.
- Upgrade to 7-Zip 18.05.
- Standardize testing environment across repos.  (AppVeyor, Kitchen, Rake, etc.)
- Upgrade development dependencies.

## 2.0.2

- Add timeout to extract action on `seven_zip` resource and configurable `default_extract_timeout` attribute.

## 2.0.1

- [GH Issue 21 - NoMethodError: Undefined method or attribute kernel on node](https://github.com/sous-chefs/seven_zip/issues/21).

## 2.0.0

- [Upgrade to 7-Zip 15.14](https://github.com/sous-chefs/seven_zip/pull/9).
- [7-Zip now installed to the default MSI location by default](https://github.com/sous-chefs/seven_zip/pull/11).
- [7z.exe is located using the Windows registry unless the home attribute is explicitly set](https://github.com/sous-chefs/seven_zip/pull/10).
- [7-Zip is only added to the Windows PATH if the syspath attribute is set](https://github.com/sous-chefs/seven_zip/pull/11).
- [Installation idempotence check was fixed](https://github.com/sous-chefs/seven_zip/pull/14), package name was corrected.
- [TravisCI build added](https://github.com/sous-chefs/seven_zip/pull/12).
- [ServerSpec tests added](https://github.com/sous-chefs/seven_zip/pull/9)
- [Document Archive LRWP](https://github.com/sous-chefs/seven_zip/pull/6)

## 1.0.2

- COOK-3476 - Upgrade to 7-zip 9.22

## 1.0.0

- initial release

---

Refer to the [Markdown Syntax Guide](https://daringfireball.net/projects/markdown/syntax) for help with standard Markdown, and [Writing on GitHub](https://help.github.com/categories/writing-on-github/) for help with the GitHub dialect of Markdown.
