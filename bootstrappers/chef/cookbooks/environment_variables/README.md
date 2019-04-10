environment_variables Cookbook
===================
This cookbook handles the application specific setup.

Requirements
------------
#### cookbooks
- `default` - sets environment variables in /etc/environment from an attributes hash

Usage
-----
#### environment_variables
Just include `environment_variables` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[environment_variables]"
  ]
}
```

Then create entries in an attribute named `environment_variables`:
```json
{
  "environment_variables": {
    "RAILS_ENV": "production",
    "S3_API_KEY": "foobar",
    "STRIPE_API_KEY": "baz"
  }
}
```

License and Authors
-------------------
Authors: [Chris Gunther](chris@room118solutions.com)
