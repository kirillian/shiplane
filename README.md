# Shiplane
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
gem 'shiplane', require: false
gem 'shiplane_bootstrappers_chef', require: false
gem 'shiplane_deployers_capistrano_docker', require: false
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

### Using Shiplane
#### TODO
