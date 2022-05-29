# Releasing A New Version of the Gem

## Pre-release Tasks
## Bundle
Update the bundle

```bash
bundle
```

## shiplane_bootstrappers_chef
When changing cookbooks, you need to run the release tasks in the boostrappers directory

```bash
cd bootstrappers/chef && rake release:refresh_cookbooks && cd ../..
```

## Bumping shiplane_bootstrappers_chef
```bash
cd bootstrappers/chef && gem bump --file lib/shiplane/bootstrappers/chef/version.rb --push --release && cd ../..
```

## Bumping shiplane_deployers_capistrano_docker
```bash
cd deployers/capistrano_docker && gem bump --file lib/shiplane/deployers/capistrano_docker/version.rb --push --release && cd ../..
```

## Bumping shiplane
gem bump --push --release
