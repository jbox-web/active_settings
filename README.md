# ActiveSettings

[![GitHub license](https://img.shields.io/github/license/jbox-web/active_settings.svg)](https://github.com/jbox-web/active_settings/blob/master/LICENSE)
[![GitHub release](https://img.shields.io/github/release/jbox-web/active_settings.svg)](https://github.com/jbox-web/active_settings/releases/latest)
[![CI](https://github.com/jbox-web/active_settings/workflows/CI/badge.svg)](https://github.com/jbox-web/active_settings/actions)
[![Maintainability](https://qlty.sh/gh/jbox-web/projects/active_settings/maintainability.svg)](https://qlty.sh/gh/jbox-web/projects/active_settings)
[![Code Coverage](https://qlty.sh/gh/jbox-web/projects/active_settings/coverage.svg)](https://qlty.sh/gh/jbox-web/projects/active_settings)

Settings in Rails.

It's heavily based on [config](https://github.com/rubyconfig/config) gem.

I made my own because I don't like the idea of having a [ghost class globally accessible](https://github.com/rubyconfig/config#accessing-the-settings-object) that I can't modify (What if I want to add some convenient methods on `Settings`?).

## Installation

Put this in your `Gemfile` :

```ruby
git_source(:github){ |repo_name| "https://github.com/#{repo_name}.git" }

# The `environment` / `platform` / env-var / schema features documented below
# live on `master`; pin an explicit `ref:`/`tag:` once a release ships them.
gem 'active_settings', github: 'jbox-web/active_settings', branch: 'master'
```

then run `bundle install`.


## Usage

### 1. Define your class

Instead of defining a `Settings` constant for you, that task is left to you. Simply create a class in your application
that looks like:

```ruby
class Settings < ActiveSettings::Base
  source      Rails.root.join('config', 'settings.yml')
  environment Rails.env
end
```

Name it `Settings`, name it `Config`, name it whatever you want. Add as many or as few as you like. A good place to put
this file in a Rails app is `config/settings.rb`


### 2. Create your settings

Notice above we specified an absolute path to our settings file called `settings.yml`. This is just a typical YAML
file, evaluated through ERB before being parsed:

```yaml
# config/settings.yml
cool:
  saweet: nested settings
neat_setting: 24
awesome_setting: <%= "Did you know 5 + 5 = #{5 + 5}?" %>
```

Keys are both accessible with a string or a symbol.

> **Security:** the file content is run through ERB, so it can execute arbitrary Ruby. Only point `source` at files
> you control — never at user-supplied input. An empty file loads as an empty config; a file that is not a YAML
> mapping raises `ActiveSettings::Error::InvalidSettingsFileError`.

#### Per-environment overrides

The optional `environment` corresponds to a **separate** file named `settings.<environment>.yml`, sitting next to
your `source` file. When it exists it is deep-merged on top of `settings.yml` (its values win); when it is absent it
is simply ignored.

```yaml
# config/settings.yml
neat_setting: 24

# config/settings.development.yml  (loaded when environment is "development")
neat_setting: 800
```

With `environment Rails.env`, booting in development yields `Settings.neat_setting == 800`, everything else falling
back to `settings.yml`.

#### Per-platform overrides

You can also declare a `platform` (e.g. `compose`, `swarm`, `kube`, `docker`, …) to layer platform-specific files
stored under a `settings_files/<platform>/` directory next to your `source` file:

```ruby
class Settings < ActiveSettings::Base
  source      Rails.root.join('config', 'settings.yml')
  environment Rails.env
  platform    ENV.fetch('PLATFORM', nil)
end
```

Files are deep-merged in this order of precedence (later wins, missing files ignored):

1. `settings.yml` (the `source`)
2. `settings.<environment>.yml`
3. `settings_files/<platform>/default.yml`
4. `settings_files/<platform>/<environment>.yml`

Finally, if enabled, environment variables are merged on top (see below).


### 3. Access your settings

You can use different methods to access to values :

* by using method chains :

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

* by using `fetch` method :

```ruby
>> Settings.cool.fetch(:saweet)
=> "nested settings"

>> Settings.cool.fetch('saweet')
=> "nested settings"
```

You can provide default value :

```ruby
>> Settings.cool.fetch(:foo, 'bar')
=> "bar"

>> Settings.cool.fetch(:foo) { 'bar' }
=> "bar"
```

* by using `[]` accessor :

```ruby
>> Settings[:cool][:saweet]
=> "nested settings"

>> Settings['cool']['saweet']
=> "nested settings"
```

* by using `dig` method :

```ruby
>> Settings.dig(:cool, :saweet)
=> "nested settings"

>> Settings.dig('cool', 'saweet')
=> "nested settings"
```

* by using `key?` method :

```ruby
>> Settings.cool.key?(:saweet)
=> "true"

>> Settings.cool.key?('saweet')
=> "true"
```

You can use these settings anywhere, for example in a model:

```ruby
class Post < ActiveRecord::Base
  self.per_page = Settings.pagination.posts_per_page
end
```

Note that `key?` and `fetch` test key **existence**, not the truthiness of the value: a key whose value is `false`
or `nil` still exists, so `Settings.fetch(:some_flag, true)` returns the stored `false` (not the default).


## Overriding with environment variables

When `ActiveSettings.use_env` is enabled, environment variables prefixed with `ActiveSettings.env_prefix` are merged
on top of the file-based configuration. Nested keys are expressed with `ActiveSettings.env_separator`:

```ruby
ActiveSettings.use_env = true # disabled by default
```

```bash
SETTINGS.NEAT_SETTING=42
SETTINGS.DEEP.NESTED.WARN_THRESHOLD=50
```

Available options (module-level, shared by every subclass — set them once at boot):

| Option                        | Default      | Description                                                        |
|-------------------------------|--------------|-------------------------------------------------------------------|
| `use_env`                     | `false`      | Enable merging of environment variables.                          |
| `env_prefix`                  | `'SETTINGS'` | Prefix that marks a variable as a setting.                        |
| `env_separator`               | `'.'`        | Separator between nested keys.                                     |
| `env_converter`               | `:downcase`  | Key case conversion (`:downcase` or `nil`).                       |
| `env_parse_values`            | `true`       | Auto-cast `true`/`false` and **base-10** numbers.                 |
| `fail_on_missing`             | `false`      | Raise `KeyError` when reading an unknown key via method access.   |
| `knockout_prefix`             | `nil`        | `deep_merge` knockout prefix.                                     |
| `merge_nil_values`            | `false`      | `deep_merge` option.                                              |
| `overwrite_arrays`            | `true`       | Replace arrays on merge instead of concatenating them.            |
| `keep_array_duplicates`       | `true`       | `deep_merge` option.                                              |

Value casting is strict base-10: `"010"` becomes `10` (not octal `8`), while hex/underscored strings such as `"0x1a"`
are kept as strings. A variable used both as a scalar and as a nested prefix (`SETTINGS.FOO` and `SETTINGS.FOO.BAR`)
raises `ActiveSettings::Error::EnvKeyConflictError`.


## Validating your settings

You can attach a [dry-schema](https://dry-rb.org/gems/dry-schema/) schema to your class and call `validate!`
explicitly (it is a no-op when no schema is defined):

```ruby
class Settings < ActiveSettings::Base
  source      Rails.root.join('config', 'settings.yml')
  environment Rails.env

  schema do
    required(:neat_setting).filled(:integer)
    required(:cool).schema do
      required(:saweet).filled(:string)
    end
  end
end

Settings.instance.validate! # raises ActiveSettings::Validation::Error on failure
```


## Storing Procs (lazy values)

A setting value may be a `Proc`; it is evaluated lazily each time the configuration is converted to a hash
(`to_hash`/`to_json`). Merging preserves stored Procs without evaluating them:

```ruby
class Settings < ActiveSettings::Base
  source Rails.root.join('config', 'settings.yml')

  def after_initialize!
    super
    merge!(computed: -> { Time.now.to_i })
  end
end
```


## Freezing

`Settings.instance.freeze` deep-freezes the whole configuration, including nested `ActiveSettings::Config`
objects and nested arrays.


## Escape hatch: storing a raw hash

By default nested mappings are wrapped into `ActiveSettings::Config` objects (accessible by method). To store a
plain `Hash` instead (accessible only by `[]`/`dig`), wrap it with a `type: hash` marker:

```yaml
raw:
  type: hash
  contents:
    any: { free: form, hash: here }
```
