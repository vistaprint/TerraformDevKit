# TerraformDevKit

[![Build Status](https://travis-ci.org/betabandido/TerraformDevKit.svg?branch=master)](https://travis-ci.org/betabandido/TerraformDevKit) [![Build status](https://ci.appveyor.com/api/projects/status/4vkyr196li83vju6/branch/master?svg=true)](https://ci.appveyor.com/project/betabandido/terraformdevkit/branch/master)

Set of scripts to ease development and testing with [Terraform](https://www.terraform.io/).

The script collection incldues support for:

* Managing AWS credentials
* Simple reading and writing to AWS DynamoDB
* Polling an AWS ApiGateway endpoint until it becomes ready
* Executing commands
* Locally installing Terraform and [Terragrunt](https://github.com/gruntwork-io/terragrunt)
* Backing up the state from a failed Terraform execution
* Multiplatform tools
* Simple configuration management

Most of these scripts exist to provide support to a module development and testing environment for Terraform: [TerraformModules](https://github.com/betabandido/TerraformModules). But, they might be useful for other purposes too.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'TerraformDevKit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install TerraformDevKit

## Usage

To use the library simply import it as:

```ruby
require 'TerraformDevKit'
```    

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/betabandido/TerraformDevKit.


## License

The gem is available as open source under the terms of the [Apache License, Version 2.0](https://opensource.org/licenses/Apache-2.0).
