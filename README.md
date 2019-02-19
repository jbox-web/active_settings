# ActiveSettings

[![GitHub license](https://img.shields.io/github/license/jbox-web/active_settings.svg)](https://github.com/jbox-web/active_settings/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/jbox-web/active_settings.svg)](https://github.com/jbox-web/active_settings/releases/latest)
[![Build Status](https://travis-ci.org/jbox-web/active_settings.svg?branch=master)](https://travis-ci.org/jbox-web/active_settings)
[![Code Climate](https://codeclimate.com/github/jbox-web/active_settings/badges/gpa.svg)](https://codeclimate.com/github/jbox-web/active_settings)
[![Test Coverage](https://codeclimate.com/github/jbox-web/active_settings/badges/coverage.svg)](https://codeclimate.com/github/jbox-web/active_settings/coverage)

Settings in Rails.

## Installation

Put this in your `Gemfile` :

```ruby
git_source(:github){ |repo_name| "https://github.com/#{repo_name}.git" }

gem 'active_settings', github: 'jbox-web/active_settings', tag: '1.0.0'
```

then run `bundle install`.


## Usage

### 1. Define your class

Instead of defining a Settings constant for you, that task is left to you. Simply create a class in your application
that looks like:

```ruby
class Settings < ActiveSettings::Base
  source    Rails.root.join('config', 'settings.yml')
  namespace Rails.env
end
```

Name it Settings, name it Config, name it whatever you want. Add as many or as few as you like. A good place to put
this file in a Rails app is `config/settings.rb`


### 2. Create your settings

Notice above we specified an absolute path to our settings file called `settings.yml`. This is just a typical YAML file.
Also notice above that we specified a namespace for our environment.  A namespace is just an optional string that corresponds
to a key in the YAML file.

Using a namespace allows us to change our configuration depending on our environment:

```yaml
# config/settings.yml
defaults: &defaults
  cool:
    saweet: nested settings
  neat_setting: 24
  awesome_setting: <%= "Did you know 5 + 5 = #{5 + 5}?" %>

development:
  <<: *defaults
  neat_setting: 800

test:
  <<: *defaults

production:
  <<: *defaults
```


### 3. Access your settings

```ruby
>> Rails.env
=> "development"

>> Settings.cool
=> "#<ActiveSettings::Config ... >"

>> Settings.cool.saweet
=> "nested settings"

>> Settings.neat_setting
=> 800

>> Settings.awesome_setting
=> "Did you know 5 + 5 = 10?"
```

You can use these settings anywhere, for example in a model:

```ruby
class Post < ActiveRecord::Base
  self.per_page = Settings.pagination.posts_per_page
end
```

Other `Enumerable` methods:

* `fetch`

```ruby
>> Settings.cool.fetch(:saweet)
=> "nested settings"

>> Settings.cool.fetch('saweet')
=> "nested settings"

>> Settings.cool.fetch(:foo)
=> "nil"

>> Settings.cool.fetch('foo')
=> "nil"

>> Settings.cool.fetch(:foo, 'bar')
=> "bar"

>> Settings.cool.fetch('foo', 'bar')
=> "bar"

>> Settings.cool.fetch(:foo) { 'bar' }
=> "bar"

>> Settings.cool.fetch('foo') { 'bar' }
=> "bar"
```

* `key?`

```ruby
>> Settings.cool.key?(:saweet)
=> "true"

>> Settings.cool.key?('saweet')
=> "true"
```

Access to nested hashes keys:

```ruby
>> Settings[:cool][:saweet]
=> "nested settings"

>> Settings['cool']['saweet']
=> "nested settings"
```

Dig in nested hashes:

```ruby
>> Settings.dig(:cool, :saweet)
=> "nested settings"

>> Settings.dig('cool', 'saweet')
=> "nested settings"
```
