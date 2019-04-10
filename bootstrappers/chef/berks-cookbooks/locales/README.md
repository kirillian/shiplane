Description
===========

This cookbook configures the available and default locales on a debian-like-system.
It also includes a LWRP for easy use in other cookbooks.

Limitation
==========

Right now the cookbook *only works with UTF-8 locales*.

Requirements
============

None

Attributes
==========

* `node[:locales][:default]` -- the default locale to be installed. Defaults to "en_US.utf8".

Usage
=====

Either use the node-attributes or the included LWRP "locales".

```ruby
locales "de_AT.utf8" do
  action :add
end
```

```ruby
locales "Add locales" do
  locales ["fr_FR.utf8", "fr_BE.utf8", "fr_CA.utf8"]
end
```

```ruby
locales "ru_RU.utf8" do
  action :set
end
```

License and Author
==================

Author: Philipp Bergsmann (<p.bergsmann@opendo.at>)

Thanks for the contributions by:
* Guilhem Lettron
* Barthélemy Vessemont
* Ed Bosher
* Christian Rodriguez

Copyright: 2013 opendo GmbH (http://opendo.at)

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
