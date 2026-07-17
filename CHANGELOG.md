# CHANGELOG

## 1.2.0 (unreleased)

* Bump required Ruby version to 3.2.0
* Bump to ActiveSupport >= 7.0
* Rename `namespace` to `environment`
* Add per-`platform` settings files (`settings_files/<platform>/…`)
* Add `on_settings_file_load` hook
* Add environment-variable overrides (`use_env`, `env_prefix`, `env_separator`, …)
* Add settings validation via dry-schema (`schema` / `validate!`)
* Allow storing `Proc` values (evaluated lazily), preserved across `merge!`
* Add `fail_on_missing` option
* Fix `key?`/`fetch` for keys whose value is `false` or `nil`
* Parse env values as strict base-10 (no accidental octal/hex coercion)
* Deep-freeze now also freezes nested arrays
* Raise explicit errors on non-mapping settings files and conflicting env keys

## 1.1.0 (2020/04/04)

* Add support of Ruby 2.7
* Add Rubocop gem
* Add binstubs to ease development
* Disable RSpec monkey-patching
* Allow to store Proc as settings value
* Add test on embedded_ruby values
* Raise an exception when source file is nil

**Notes :**

This is the last version to support Ruby 2.4.x

## 1.0.0 (2019/02/19)

First release!
