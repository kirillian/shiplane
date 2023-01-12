![Shiplane](assets/shiplane_logo.jpg)

Convert your development docker-compose yaml files into production-ready docker deployments

## The Mission

### Empower Developers
Shiplane is about empowering developers to get more done, in less time, with less effort. It is intended to amplify a developer's skills and efforts for little cost. It shouldn't take hours and days to setup a working Shiplane environment. It should take minutes to get a working, sane, and relatively secure solution out of the box. Once working, everything should be tweakable as needed.

### Platform Agnostic
Shiplane doesn't care what language you use, what orchestration tool you use, or even what kind of OS you are deploying to or from. Shiplane is merely a well-traveled, sane, and easy to use path through the Docker ecosystem that gets you from having nothing to having a working system.

## What does Shiplane do for me?

### Environment Consistency
Your development compose environment already defines all your application's dependencies, so why should you need to recreate your entire environment just to deploy to production? It not only duplicates work, but increases the likelihood of differences between environments that developers are always attempting to mitigate. Shiplane helps you minimize any differences so that the transition from your local, development Docker environment is just another push of code to your CI.

### Taming the Wild West
The sheer number of Docker tools out there is staggering. While they all solve some problem, it can be difficult to decide WHICH tools you want to chain together to make your toolset as a developer new to the Docker ecosystem. Maybe you're not as big as Google and you don't need Kubernetes right now or maybe you just picked up Docker last week, but see it's potential and you're seeking the quickest path to a pipeline right now despite not understanding everything just yet. Shiplane is designed to help you move from having nothing to having a complete Docker ecosystem in a matter of minutes - not hours, days, or weeks.

### Appropriate division of responsibilities
Docker places a lot of power in the hands of developers to define and manage their development environments and how their code is deployed. This is both good and bad. The good side of things includes developers no longer being subject to the work of other groups in your company to provision and deploy. However, the downsides include things like developers having control over platform security, the keys to the kingdom, and infrastructure. While these aren't necessarily evil, these are typically the domain of an infrastructure team to whom these responsibilities are specifically designated. How can these responsibilities be delegated appropriately without taking away the power that the Docker ecosystem provides developers? There are some existing ways to solve these problems, but they require complex systems to be setup to do so. Shiplane is DESIGNED to make this happen out of the box from day 1. It is designed specifically to allow infrastructure teams to be inserted into the process before developers do any work (infrastructure/security can provide base docker images) and during the CI pipeline (so that infrastructure/security teams can manage keys). This allows you to deploy a docker ecosystem quickly and easily with Shiplane and remain confident that you start off pretty secure and are able to continue using it as your processes evolve.

### Makes it easy to adapt and scale
Shiplane is actually designed to be easy to use early on in the process, scale with you, be easy to switch to new tools (say you want to switch from a pure Docker deployment to using Kubernetes), and yet be easy to get rid of should you decide it is no longer for you.

### Ok, surely there has to be a catch?
#### Not really, no. Ok, one minor catch (that you can help me with by contributing!)
While Shiplane is language and platform agnostic and you will be able to deploy that Python project or your Java project, it is written in Ruby at this time and therefore requires your machine to have Ruby installed. The instructions for doing so are included below. That's it. That's the only caveat. And, if you are so inclined, I would LOVE to accept PRs to help me create a Shiplane binary or otherwise remove this dependency entirely. There is an issue open [here](https://github.com/kirillian/shiplane/issues/11) to discuss this problem and potential fixes for it.

## Installation

### Installing Ruby
#### TODO

### Installing Shiplane
#### Installing locally to a project
1. Install Bundler if you don't already have it:
```sh
gem install bundler
```

2. You can install Shiplane by adding (if you already have one, skip this first step) a Gemfile with the following contents:
```Gemfile
source 'https://rubygems.org'

ruby '2.6.2'
```

3. Add the following lines to your Gemfile:
```
gem 'shiplane'
gem 'shiplane_bootstrappers_chef'
gem 'shiplane_deployers_capistrano_docker'
```

4. Run bundler to install everything:
```sh
bundle install
```

#### Installing globally
```sh
gem install shiplane
gem install shiplane_bootstrappers_chef
gem install shiplane_deployers_capistrano_docker
```

### Adding the shiplane.yml to your project folder
You will need to have a shiplane.yml file in your project's folder in order to configure shiplane.
You can generate a default version of this file via the following command:
```sh
rake shiplane:install[<application_name>]
```

Reference the example [shiplane.ymls](examples/rails_app/shiplane.yml) for some ideas on how to configure your app.

> **WARNING**: Make sure to configure your shiplane.yml here. The following commands make use of some or all of those configurations!!

### Using Shiplane
#### Steps involved in provisioning and deploying
Currently, Shiplane assumes you have an empty VM/VPS/Metal Box with some form of linux on it (though testing has primarily been done on Ubuntu boxes). Shiplane assumes an otherwise EMPTY install. It is HIGHLY recommended that you NOT use Shiplane (or any other provisioning) on an install with software other than a basic OS installed.

Each of the following steps are handled in Shiplane:
- Bootstrapping
- Provisioning
- Building
- Deploying

#### Bootstrapping
This step is closely related to provisioning and is currently tied in with provisioning itself, but the concept remains a separate entity and may be separated from provisioning sometime in the future.

During bootstrapping, Shiplane ssh's into the deployment target you have designated for provisioning and installs the bare minimum necessary software to allow provisioning.

Currently the following Bootstrappers are provided:
- shiplane_bootstrappers_chef `# Installs Chef and uploads cookbooks for the provisioner`

#### Provisioning
During Provisioning Shiplane installs all the software necessary to run the selected deployment framework on the deployment target.

Currently, the following Provisioners are provided:
- shiplane_bootstrappers_chef `# Uses Chef Solo to install deployment frameworks`

You can bootstrap AND provision at once by running the following:
```sh
bundle exec cap production shiplane:bootstrap
```

#### Building
Shiplane provides rake tasks that may be used to build your Docker containers into Production-ready containers and upload the images to a registry for download on your target deployment machine. Currently, Shiplane supports Dockerhub out of the box.

It is intended that this be integrated into your CI pipeline and some examples are provided (Currently, we provide an example for Circle CI).

Configuration for building is provided by the `shiplane.yml` file that has already been mentioned and any files in the `.shiplane` folder. Under this folder, any files under `insert_on_build` will be inserted into you application structure during the build process. e.g. in the [rails_app](examples/rails_app) example, the config folder will be inserted into the docker container during the build process. ERB files can be evaluated by shiplane to provide files with keys or other such things inserted. The `production_dockerfile_stages` file under the `.shiplane` folder utilizes docker's multistage building technique to take your local dockerfile and append new stages that give you the chance to perform any pre-production stages you might need. See the [example](examples/rails_app/.shiplane/production_dockerfile_stages) for a sample of what you might do yourself.

You can build a docker container based on the HEAD of your current branch like so:
```sh
bundle exec cap production shiplane
```

### Environment Variables
Shiplane uses specific .env files to make sure that a given build environment contains the appropriate environment variables. These are used for 3 separate purposes:
- The environment that the Shiplane process is running in. For example, if you want to authenticate with a Github private repo, you will need to set the GITHUB_TOKEN environment variable in your .env file so that Shiplane can authenticate.
- The buildtime step of building the container. If your container needs environment variables to be set during buildtime so that the container can be built, you will need these builtime env variables. Examples might include a Github Token used to pull dependencies from private repositories on Github during buildtime. These variables will not be stored in your container, but you may need to remove any traces of these variables that might be stored in your container as side effects if your dependency ecosystem does this. For example, Ruby Gems downloaded during buildtime using an Github Token will result in that token being stored in the Gemfile.lock file. The [examples folder](examples/rails_app/.shiplane/production_dockerfile_stages) provide an example of a means of removing this after bundling. You may consider a similar step during your build process.
- The runtime environment may require some environment variables. For example, you might have a bunch of ENVIRONMENT VARIABLES necessary for your application to run (less secure, but simpler), or, you might need an environment variable to access a vault somewhere containing other runtime ENVIRONMENT VARIABLES (more secure, slightly more difficult), or, you may have none at all and use another mechanism to inject appropriate settings (you have more control over this, but the most difficult).

## Important ENVIRONMENT VARIABLES for the Shiplane Process
```sh
GITHUB_TOKEN=XXXXXXXXXX # required if pulling from a private Github Repository
BITBUCKET_TOKEN=XXXXXXXXXX # required if pulling from a private Bitbucket Repository
BITBUCKET_USERNAME=XXXXXXXXXX # required if pulling from a private Bitbucket Repository
```

## Important ENVIRONMENT VARIABLES for buildtime
```sh
DOCKERHUB_PASSWORD=XXXXXXXXXX # deprecated but still supported token/password specifically for DOCKERHUB
DOCKERHUB_USERNAME=XXXXXXXXXX # deprecated but still supported username specifically for DOCKERHUB
SHIPLANE_CONTAINER_REGISTRY_TOKEN=XXXXXXXXXX # Token for container registry authentication
SHIPLANE_CONTAINER_REGISTRY_USERNAME=XXXXXXXXXX # Username for container registry authentication
RAISE_EXCEPTIONS_ON_FAILED_BUILD=true # Tells Shiplane to stop on a failed build and raise an exception. Defaults to 'false'
DOCKER_COMPOSE_V1_COMPATIBILITY=true # Set this if you are using docker-compose or using docker compose in compatibility mode. See this StackOverflow Question for some details: https://stackoverflow.com/questions/69464001/docker-compose-container-name-use-dash-instead-of-underscore
```
## Important ENVIRONMENT VARIABLES for runtime
# Rails Environment Variable sample
```sh
RAILS_MASTER_KEY=XXXXXXXXXX
```

#### Deploying
Shiplane provides tasks to help you deploy your code. These tasks depend on your deployment framework, but each task appropriately launches your docker containers on your selected framework.

Currently, the following Deployers are provided:
- shiplane_deployers_capistrano_docker `# Uses Capistrano and Raw Docker to run your containers`

The Capistrano deployer uses Capistrano's configuration. You can see an example of how this works under the [examples folder](examples/rails_app/config/deploy.rb)

You can run a deployment like so:
```sh
bundle exec cap production deploy
```

You can also deploy a specific Git SHA using the following syntax:

```sh
bundle exec cap production deploy[<sha>]
```

### Troubleshooting
This is as much a reminder to me as anyone else. If a new version of the gem has just been released and you are trying to pull it, make sure to run the following if bundler fails:
```
bundle install --full-index
```

##### [Rails Application] `Could not load database configuration. No such file - ["config/database.yml"]`
If you are receiving similar messages during the build process, this likely means that you are running a task during the build (e.g. asset precompilation) that is loading up the Rails initializers and have an initializer that tries to connect to the database. You can fix this by finding which of your initializers is being called. See this snippet here from an app that shows where you would find the offending initializer:
```
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/zeitwerk-2.1.6/lib/zeitwerk/kernel.rb:23:in `require'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:302:in `block in require'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:268:in `load_dependency'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:302:in `require'
/var/www/surveyor/config/initializers/public_activity.rb:1:in `<main>'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/bootsnap-1.4.4/lib/bootsnap/load_path_cache/core_ext/kernel_require.rb:54:in `load'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/bootsnap-1.4.4/lib/bootsnap/load_path_cache/core_ext/kernel_require.rb:54:in `load'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:296:in `block in load'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:268:in `load_dependency'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/activesupport-6.0.0.rc1/lib/active_support/dependencies.rb:296:in `load'
/var/www/surveyor/vendor/bundle/ruby/2.6.0/gems/railties-6.0.0.rc1/lib/rails/engine.rb:668:in `block in load_config_initializer'
```

To fix this, wrap the offending code in the initializer with this helper provided by Shiplane:
```
require 'shiplane/safe_build'

Shiplane::SafeBuild.wrap do
  PublicActivity::Activity.class_eval do
    belongs_to :true_owner, polymorphic: true
  end
end
```

#### Using Build Cache
Shiplane is designed to always build using the --no-cache flag in order to guaranteee clean, repeatable builds, but if you find yourself troubleshooting or otherwise needing to build multiple times, you might like to use the following flag to speed up the process. Note that this is intended to be a debugging tool. Using it for production building could potentially part of the build process to run in one context and another part to run in another. Such a case might cause both positive and negative results that are difficult to troubleshoot because they are not repeatable. Don't do this, but DO use this responsibly to make your life easier when troubleshooting.

`USE_BUILD_CACHE=true bundle exec cap production shiplane`

## Becoming Involved
### Community Channels
You can join our [Discord community](https://discord.gg/drrn2YG) to ask any questions you might have or to get ahold of someone in the community who might be able to help you (I hang out here just about every day of the week and most of the weekend). There is no guarantee of service implied, but we absolutely believe in helping out our fellow developers and will do so as we are able. If you feel you know some stuff about Shiplane, feel free to hang out and please help out as well!

### Contributing

We highly encourage you to contribute to Shiplane! Check out the [Contribution Guidelines](CONTRIBUTING.md) and help make Shiplane better!

Everyone interacting in Shiplane's codebase, issue trackers, and chatroom is expected to follow the [Code of Conduct](CODE_OF_CONDUCT.md)

### Security Concerns
If you have a security concern with Shiplane, please follow our Security Policy guidelines to submit the issue to us.

## License

Shiplane is released under the [MIT License](LICENSE).
