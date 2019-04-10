# Cookbook: Chef Server with Let's Encrypt

A simple wrapper cookbook that sets up Chef Server with a trusted SSL/TLS certificate from Let's Encrypt.
Uses [chef-server cookbook][chef-server] and [Lego library](lego).

[chef-server]: https://supermarket.chef.io/cookbooks/chef-server
[lego]: https://github.com/xenolf/lego


## Usage

### Validation

You must override `lego_email` attribute to obtain a certificate.

```
default['chef-server-with-letsencrypt']['lego_email'] = 'you@example.com'
```

### Validation by DNS

By default, HTTP method is used to validate domain `lego --http :80`).

Override default attributes to use DNS method.
Consult `lego dnshelp` for required environment variables.

Example:

```ruby
default['chef-server-with-letsencrypt']['lego_params'] = '--dns dnsimple'
default['chef-server-with-letsencrypt']['lego_env'] = {'DNSIMPLE_EMAIL' => '...', 'DNSIMPLE_OAUTH_TOKEN' => '...'}
```

### Other attributes

Look up [attributes/default.rb][attributes.rb] for available overrides
and [kitchen.yml][kitchen.yml] for ideas how to use them in practice.

[attributes.rb]: https://gitlab.com/virtkick/chef-server-with-letsencrypt/blob/feature/docker-gitlab-ci/attributes/default.rb
[kitchen.yml]: https://gitlab.com/virtkick/chef-server-with-letsencrypt/blob/feature/docker-gitlab-ci/.kitchen.yml


## Development

### Bundler

We use `chef` gem from Rubygems. We **don't** use Chef DK.
Always call all Chef utilities (e.g. `chef`, `knife`, `berks`, `kitchen` or whatever) via Bundler.
Example:

`x knife node list`

### First setup

1. `alias x='bundle exec'`
2. `curl -sSL https://get.rvm.io | bash -s stable`
4. `gem install bundler`

### Daily routine

At the very minimum, before `git commit` and after `git pull`.

2. `bundle`
3. `x berks`

### Testing

We use [Test Kitchen](http://kitchen.ci/) to test cookbooks.
The basics:

- `x kitchen converge` to provision the test machine with Chef
- `x kitchen verify` to run tests on the machine
- `x kitchen login` to manually inspect the machine


## License and Authors

- Author: Damian Nowak [nowaker@virtkick.com](mailto:nowaker@virtkick.com)
- Author: Rafal Lisewski [rafalski@virtkick.com](mailto:rafalski@virtkick.com)
- Copyright 2017, Virtkick, Inc.

```text
Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```
