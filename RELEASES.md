# Releasing A New Version of the Gem

## Bumping shiplane_bootstrappers_chef
cd bootstrappers/chef && gem bump --file lib/shiplane/bootstrappers/chef/version.rb --push --release && cd ../..

## Bumping shiplane_deployers_capistrano_docker
cd deployers/capistrano_docker && gem bump --file lib/shiplane/deployers/capistrano_docker/version.rb --push --release && cd ../..

## Bumping shiplane
gem bump --push --release
