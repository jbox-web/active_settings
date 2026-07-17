# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveSettings::Base do

  context 'when source file is nil' do
    let(:settings) { Class.new(described_class) }

    let(:instance) { settings.instance }

    it 'raises an error' do
      expect {
        instance
      }.to raise_error(ActiveSettings::Error::SourceFileNotDefinedError)
    end
  end

  context 'when source file is empty' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source get_fixture_path('empty.yml')
      end
    end

    let(:instance) { settings.instance }

    it 'does not raise and loads an empty config', :aggregate_failures do
      expect { instance }.to_not raise_error
      expect(instance.to_hash).to eq({})
    end
  end

  context 'when source file is not a mapping' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source get_fixture_path('invalid_scalar.yml')
      end
    end

    let(:instance) { settings.instance }

    it 'raises an explicit error' do
      expect {
        instance
      }.to raise_error(ActiveSettings::Error::InvalidSettingsFileError)
    end
  end

  context 'without environment' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source get_fixture_path('settings.yml')
      end
    end

    let(:instance) { settings.instance }

    describe '#source' do
      it 'delegates to class method' do
        expect(instance.source).to eq get_fixture_path('settings.yml')
      end
    end

    describe '#environment' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source get_fixture_path('settings.yml')
          environment 'foo'
        end
      end

      let(:instance) { settings.instance }

      it 'delegates to class method' do
        expect(instance.environment).to eq 'foo'
      end
    end

    describe 'settings accesors' do
      it 'accesses settings by method' do
        expect(instance.foo).to eq 'bar'
      end

      it 'accesses nested settings by method' do
        expect(instance.nested.foo).to eq 'bar'
      end

      it 'accesses settings by string key' do
        expect(instance['foo']).to eq 'bar'
      end

      it 'accesses nested settings by string key' do
        expect(instance['nested']['foo']).to eq 'bar'
      end

      it 'accesses settings by symbol key' do
        expect(instance[:foo]).to eq 'bar'
      end

      it 'accesses nested settings by symbol key' do
        expect(instance[:nested][:foo]).to eq 'bar'
      end
    end

    describe '#key?' do
      context 'when string key exist' do
        it 'returns true' do
          expect(instance.key?('foo')).to be true
        end
      end

      context 'when string key dont exist' do
        it 'returns false' do
          expect(instance.key?('bar')).to be false
        end
      end

      context 'when symbol key exist' do
        it 'returns true' do
          expect(instance.key?(:foo)).to be true
        end
      end

      context 'when symbol key dont exist' do
        it 'returns false' do
          expect(instance.key?(:bar)).to be false
        end
      end

      context 'when nested string key exist' do
        it 'returns true' do
          expect(instance.nested.key?('foo')).to be true
        end
      end

      context 'when nested string key dont exist' do
        it 'returns false' do
          expect(instance.nested.key?('bar')).to be false
        end
      end

      context 'when nested symbol key exist' do
        it 'returns true' do
          expect(instance.nested.key?(:foo)).to be true
        end
      end

      context 'when nested symbol key dont exist' do
        it 'returns false' do
          expect(instance.nested.key?(:bar)).to be false
        end
      end

      context 'when key exists but its value is falsy' do
        it 'returns true for a false value' do
          expect(instance.key?(:bool_false)).to be true
        end
      end
    end

    describe '#fetch' do
      context 'when string key exist' do
        it 'returns value' do
          expect(instance.fetch('foo')).to eq 'bar'
        end
      end

      context 'when string key dont exist' do
        it 'returns nil' do
          expect(instance.fetch('bar')).to be_nil
        end
      end

      context 'when symbol key exist' do
        it 'returns value' do
          expect(instance.fetch(:foo)).to eq 'bar'
        end
      end

      context 'when symbol key dont exist' do
        it 'returns nil' do
          expect(instance.fetch(:bar)).to be_nil
        end
      end

      context 'when nested string key exist' do
        it 'returns value' do
          expect(instance.nested.fetch('foo')).to eq 'bar'
        end
      end

      context 'when nested string key dont exist' do
        it 'returns nil' do
          expect(instance.nested.fetch('bar')).to be_nil
        end
      end

      context 'when nested symbol key exist' do
        it 'returns value' do
          expect(instance.nested.fetch(:foo)).to eq 'bar'
        end
      end

      context 'when nested symbol key dont exist' do
        it 'returns nil' do
          expect(instance.nested.fetch(:bar)).to be_nil
        end
      end

      context 'when key dont exist and a default value is given' do
        it 'returns default value' do
          expect(instance.fetch(:path, 'foo')).to eq 'foo'
        end
      end

      context 'when key dont exist and a block is given' do
        # rubocop:disable Style/RedundantFetchBlock
        it 'yields block' do
          expect(instance.fetch(:path) { 'foo' }).to eq 'foo'
        end
        # rubocop:enable Style/RedundantFetchBlock
      end

      context 'when key exists with a false value' do
        it 'returns the false value, not the default' do
          expect(instance.fetch(:bool_false, 'default')).to be false
        end
      end
    end

    describe '#dig' do
      context 'when nested string key exist' do
        it 'returns value' do
          expect(instance.dig('nested', 'foo')).to eq 'bar'
        end
      end

      context 'when nested string key dont exist' do
        it 'returns nil' do
          expect(instance.dig('nested', 'bar')).to be_nil
        end
      end

      context 'when nested symbol key exist' do
        it 'returns value' do
          expect(instance.dig(:nested, :foo)).to eq 'bar'
        end
      end

      context 'when nested symbol key dont exist' do
        it 'returns nil' do
          expect(instance.dig(:nested, :bar)).to be_nil
        end
      end
    end

    describe '#each' do
      it 'iterates on Settings' do
        expect(instance.each.to_h).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: ActiveSettings::Config.new(foo: 'bar'),
          deep: ActiveSettings::Config.new(nested: ActiveSettings::Config.new(warn_threshold: 100)),
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            ActiveSettings::Config.new(foo: 'bar'),
            ActiveSettings::Config.new(baz: 'bar'),
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            ActiveSettings::Config.new(foo: 'bar'),
          ],
          embedded_ruby: 6,
        })
      end
    end

    describe '#to_hash' do
      it 'returns config as hash' do
        expect(instance.to_hash).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar',
          },
          deep: {
            nested: {
              warn_threshold: 100,
            },
          },
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            { foo: 'bar' },
            { baz: 'bar' },
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            { foo: 'bar' },
          ],
          embedded_ruby: 6,
        })
      end
    end

    describe '#to_h' do
      it 'returns config as hash' do
        expect(instance.to_h).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar',
          },
          deep: {
            nested: {
              warn_threshold: 100,
            },
          },
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            { foo: 'bar' },
            { baz: 'bar' },
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            { foo: 'bar' },
          ],
          embedded_ruby: 6,
        })
      end
    end

    describe '#to_json' do
      # rubocop:disable Layout/LineLength
      let(:json) { '{"bool_true":true,"bool_false":false,"string":"foo","integer":1,"float":1.0,"foo":"bar","nested":{"foo":"bar"},"deep":{"nested":{"warn_threshold":100}},"ary":["foo","bar"],"ary_of_hash":[{"foo":"bar"},{"baz":"bar"}],"ary_of_ary":[["foo","bar"],["baz","bar"]],"ary_of_mix":[["foo","bar"],{"foo":"bar"}],"embedded_ruby":6}' }

      it 'returns config as json' do
        expect(instance.to_json).to eq json
      end
      # rubocop:enable Layout/LineLength
    end

    describe '.fail_on_missing' do
      context 'when fail_on_missing is false' do
        it 'does not raise error when accessing missing key' do
          expect {
            instance.path
          }.to_not raise_error
        end

        it 'does not raise error when accessing missing nested key' do
          expect {
            instance.nested.path
          }.to_not raise_error
        end

        it 'returns nil when accessing missing nested key' do
          expect(instance.nested.path).to be_nil
        end
      end

      context 'when fail_on_missing is true' do
        before { ActiveSettings.fail_on_missing = true }
        after  { ActiveSettings.fail_on_missing = false }

        it 'raises error when accessing missing key' do
          expect {
            instance.path
          }.to raise_error(KeyError).with_message('key not found: :path')
        end

        it 'raises error when accessing nested missing key' do
          expect {
            instance.nested.path
          }.to raise_error(KeyError).with_message('key not found: :path')
        end
      end
    end

    describe '#merge' do
      it 'merges hash' do
        expect(instance.merge!(baz: 'bar').to_hash).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          baz: 'bar',
          nested: {
            foo: 'bar',
          },
          deep: {
            nested: {
              warn_threshold: 100,
            },
          },
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            { foo: 'bar' },
            { baz: 'bar' },
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            { foo: 'bar' },
          ],
          embedded_ruby: 6,
        })
      end

      it 'merges nested hash' do
        expect(instance.merge!(nested: { baz: 'bar' }).to_hash).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar',
            baz: 'bar',
          },
          deep: {
            nested: {
              warn_threshold: 100,
            },
          },
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            { foo: 'bar' },
            { baz: 'bar' },
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            { foo: 'bar' },
          ],
          embedded_ruby: 6,
        })
      end

      context 'when overwrite_arrays is true (default)' do
        it 'merge/overwrites nested ary' do
          expect(instance.merge!(ary: ['baz']).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'baz',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end

        it 'merge/overwrites nested ary of hash' do
          expect(instance.merge!(ary_of_hash: [{ foo: 'bar' }]).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end

        it 'merge/overwrites nested ary of ary' do
          expect(instance.merge!(ary_of_ary: [['foo', 'bar']]).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'when overwrite_arrays is false' do
        before { ActiveSettings.overwrite_arrays = false }
        after  { ActiveSettings.overwrite_arrays = true }

        it 'merge/extends nested ary' do
          expect(instance.merge!(ary: ['baz']).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
              'baz',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end

        it 'merge/extends nested ary of hash' do
          expect(instance.merge!(ary_of_hash: [{ foo: 'baz' }]).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
              { foo: 'baz' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end

        it 'merge/extends nested ary of ary' do
          expect(instance.merge!(ary_of_ary: [['foo', 'baz']]).to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
              ['foo', 'baz'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end
    end

    describe '#merge with Procs' do
      it 'does not eagerly evaluate stored Procs', :aggregate_failures do
        calls = 0
        lazy = lambda do
          calls += 1
          'value'
        end

        # rubocop:disable Performance/RedundantMerge
        instance.merge!(lazy: lazy)
        instance.merge!(nested: { added: 'y' })
        # rubocop:enable Performance/RedundantMerge

        expect(calls).to eq 0
        expect(instance.to_hash[:lazy]).to eq 'value'
        expect(calls).to eq 1
      end
    end

    describe '#validate!' do
      context 'when schema is not defined' do
        it 'does nothing' do
          expect {
            instance.validate!
          }.to_not raise_error
        end
      end

      context 'when schema is defined' do
        let(:with_valid_schema) do
          Class.new(ActiveSettings::Base) do
            source get_fixture_path('settings.yml')

            schema do
              required(:foo).filled
              required(:nested).schema do
                required(:foo).filled
              end
            end
          end
        end

        let(:with_invalid_schema) do
          Class.new(ActiveSettings::Base) do
            source get_fixture_path('settings.yml')

            schema do
              required(:bar).filled
            end
          end
        end

        context 'when schema is valid' do
          it 'validates settings' do
            expect {
              with_valid_schema.instance.validate!
            }.to_not raise_error
          end
        end

        context 'when schema is invalid' do
          it 'validates settings' do
            expect {
              with_invalid_schema.instance.validate!
            }.to raise_error(ActiveSettings::Validation::Error)
          end
        end
      end
    end

    describe '#freeze' do
      def deep_array_validation(array)
        array.map do |value|
          if value.instance_of?(ActiveSettings::Config)
            deep_config_validation(value)
          elsif value.instance_of?(Array)
            deep_array_validation(value)
          end
        end
      end

      def deep_config_validation(hash)
        hash.each_value do |v|
          if v.instance_of?(ActiveSettings::Config)
            expect(v.frozen?).to be true
            deep_config_validation(v)
          elsif v.instance_of?(Array)
            deep_array_validation(v)
          end
        end
      end

      it 'deep freeze object' do
        instance.freeze
        expect(instance.frozen?).to be true
        deep_config_validation(instance)
      end

      it 'also freezes nested arrays', :aggregate_failures do
        instance.freeze
        expect(instance.ary.frozen?).to be true
        expect(instance.ary_of_ary.frozen?).to be true
        expect(instance.ary_of_ary.first.frozen?).to be true
        expect { instance.ary << 'baz' }.to raise_error(FrozenError)
      end
    end

    context 'when use_env is true' do
      context 'with boolean' do
        context 'when boolean is false' do
          before do
            ActiveSettings.use_env = true
            ENV['SETTINGS.BOOL_TRUE'] = 'false'
          end

          after do
            ActiveSettings.use_env = false
            ENV.delete('SETTINGS.BOOL_TRUE')
          end

          it 'loads settings from env vars' do
            expect(instance.to_hash).to eq({
              bool_true: false,
              bool_false: false,
              string: 'foo',
              integer: 1,
              float: 1.0,
              foo: 'bar',
              nested: {
                foo: 'bar',
              },
              deep: {
                nested: {
                  warn_threshold: 100,
                },
              },
              ary: [
                'foo',
                'bar',
              ],
              ary_of_hash: [
                { foo: 'bar' },
                { baz: 'bar' },
              ],
              ary_of_ary: [
                ['foo', 'bar'],
                ['baz', 'bar'],
              ],
              ary_of_mix: [
                ['foo', 'bar'],
                { foo: 'bar' },
              ],
              embedded_ruby: 6,
            })
          end
        end

        context 'when boolean is true' do
          before do
            ActiveSettings.use_env = true
            ENV['SETTINGS.BOOL_TRUE'] = 'true'
          end

          after do
            ActiveSettings.use_env = false
            ENV.delete('SETTINGS.BOOL_TRUE')
          end

          it 'loads settings from env vars' do
            expect(instance.to_hash).to eq({
              bool_true: true,
              bool_false: false,
              string: 'foo',
              integer: 1,
              float: 1.0,
              foo: 'bar',
              nested: {
                foo: 'bar',
              },
              deep: {
                nested: {
                  warn_threshold: 100,
                },
              },
              ary: [
                'foo',
                'bar',
              ],
              ary_of_hash: [
                { foo: 'bar' },
                { baz: 'bar' },
              ],
              ary_of_ary: [
                ['foo', 'bar'],
                ['baz', 'bar'],
              ],
              ary_of_mix: [
                ['foo', 'bar'],
                { foo: 'bar' },
              ],
              embedded_ruby: 6,
            })
          end
        end
      end

      context 'with nested hash' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.NESTED.BAZ'] = 'bar'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.NESTED.BAZ')
        end

        it 'loads settings from env vars' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
              baz: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'with deep nested hash' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.DEEP.NESTED.BAZ'] = 'bar'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.DEEP.NESTED.BAZ')
        end

        it 'loads settings from env vars' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
                baz: 'bar',
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'when ENV is empty' do
        # rubocop:disable RSpec/InstanceVariable
        before do
          ActiveSettings.use_env = true
          @old_env = ENV.to_hash
          ENV.clear
        end

        after do
          ActiveSettings.use_env = false
          ENV.update(@old_env)
        end
        # rubocop:enable RSpec/InstanceVariable

        it 'loads settings from env vars' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'when env_prefix is nil' do
        before do
          ActiveSettings.use_env = true
          ActiveSettings.env_prefix = nil
        end

        after do
          ActiveSettings.use_env = false
          ActiveSettings.env_prefix = 'SETTINGS'
        end

        it 'raises error' do
          expect {
            instance.to_hash
          }.to raise_error(ActiveSettings::Error::EnvPrefixNotDefinedError)
        end
      end

      context 'when a value is a zero-padded number' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.INTEGER'] = '010'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.INTEGER')
        end

        it 'parses it as decimal, not octal' do
          expect(instance.integer).to eq 10
        end
      end

      context 'when a value is a hex string' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.STRING'] = '0x1a'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.STRING')
        end

        it 'keeps it as a string' do
          expect(instance.string).to eq '0x1a'
        end
      end

      context 'when a scalar key and a nested key collide' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.FOO'] = '5'
          ENV['SETTINGS.FOO.BAR'] = '9'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.FOO')
          ENV.delete('SETTINGS.FOO.BAR')
        end

        it 'raises an explicit conflict error' do
          expect {
            instance.to_hash
          }.to raise_error(ActiveSettings::Error::EnvKeyConflictError)
        end
      end
    end
  end

  context 'with environment' do
    context 'when environment is development' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source get_fixture_path('settings_with_environment.yml')
          environment 'development'
        end
      end

      let(:instance) { settings.instance }

      describe '#to_hash' do
        it 'returns config as hash' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'baz',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 50,
                warn_account: 'foo',
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'when use_env is true' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.DEEP.NESTED.WARN_ACCOUNT'] = 'bar'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.DEEP.NESTED.WARN_ACCOUNT')
        end

        it 'loads settings from env vars' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'baz',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 50,
                warn_account: 'bar',
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end
    end

    context 'when environment is production' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source get_fixture_path('settings_with_environment.yml')
          environment 'production'

          schema do
            required(:foo).filled
            required(:nested).schema do
              required(:foo).filled
            end

            required(:deep).schema do
              required(:nested).schema do
                required(:warn_threshold).filled
                required(:warn_account).filled
              end
            end
          end
        end
      end

      let(:instance) { settings.instance }

      describe '#to_hash' do
        it 'returns config as hash' do
          expect(instance.to_hash).to eq({
            bool_true: false,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
                warn_account: 'foo',
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end

      context 'when use_env is true' do
        before do
          ActiveSettings.use_env = true
          ENV['SETTINGS.DEEP.NESTED.WARN_ACCOUNT'] = 'bar'
        end

        after do
          ActiveSettings.use_env = false
          ENV.delete('SETTINGS.DEEP.NESTED.WARN_ACCOUNT')
        end

        it 'loads settings from env vars' do
          expect(instance.to_hash).to eq({
            bool_true: false,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar',
            },
            deep: {
              nested: {
                warn_threshold: 100,
                warn_account: 'bar',
              },
            },
            ary: [
              'foo',
              'bar',
            ],
            ary_of_hash: [
              { foo: 'bar' },
              { baz: 'bar' },
            ],
            ary_of_ary: [
              ['foo', 'bar'],
              ['baz', 'bar'],
            ],
            ary_of_mix: [
              ['foo', 'bar'],
              { foo: 'bar' },
            ],
            embedded_ruby: 6,
          })
        end
      end
    end
  end

  context 'with platform' do
    let(:base_file) { get_fixture_path('settings_with_environment.yml') }

    describe '#platform' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source    get_fixture_path('settings_with_environment.yml')
          platform  'docker'
        end
      end

      let(:instance) { settings.instance }

      it 'delegates to class method' do
        expect(instance.platform).to eq 'docker'
      end
    end

    context 'with platform only (no environment)' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source   get_fixture_path('settings_with_environment.yml')
          platform 'docker'
        end
      end

      let(:instance) { settings.instance }

      it 'merges platform default over base settings' do
        expect(instance.foo).to eq 'platform_default'
      end

      it 'adds platform-specific keys' do
        expect(instance.platform_key).to eq 'docker'
      end

      it 'keeps base keys not overridden by platform' do
        expect(instance.nested.foo).to eq 'bar'
      end
    end

    context 'with platform and environment' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source      get_fixture_path('settings_with_environment.yml')
          environment 'development'
          platform    'docker'
        end
      end

      let(:instance) { settings.instance }

      it 'applies overrides in order: base → env → platform default → platform+env' do
        expect(instance.foo).to eq 'platform_dev'
      end

      it 'keeps platform default keys not overridden by platform+env' do
        expect(instance.platform_key).to eq 'docker'
      end

      it 'keeps env-specific keys not overridden by platform' do
        expect(instance.deep.nested.warn_threshold).to eq 50
      end
    end

    context 'when platform default file does not exist' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source   get_fixture_path('settings_with_environment.yml')
          platform 'unknown_platform'
        end
      end

      let(:instance) { settings.instance }

      it 'does not raise error' do
        expect { instance }.to_not raise_error
      end

      it 'falls back to base settings' do
        expect(instance.foo).to eq 'bar'
      end
    end

    context 'when platform+env file does not exist' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source      get_fixture_path('settings_with_environment.yml')
          environment 'production'
          platform    'docker'
        end
      end

      let(:instance) { settings.instance }

      it 'does not raise error' do
        expect { instance }.to_not raise_error
      end

      it 'falls back to platform default' do
        expect(instance.foo).to eq 'platform_default'
      end
    end
  end

  context 'with custom settings' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source get_fixture_path('settings_with_environment.yml')
        environment 'production'

        def after_initialize!
          super
          load_storage_config!
        end

        def load_storage_config!
          hash = {}
          ['private', 'public'].each do |prefix|
            hash["#{prefix}_documents"] = {}
            hash["#{prefix}_documents"]['path'] = "/documents/#{prefix}"
            hash["#{prefix}_documents"]['size'] = -> { "size_of_#{prefix}" }
            hash["#{prefix}_documents"]['test'] = [-> { 'lambda2' }, -> { 'lambda1' }]
          end
          merge!(hash)
        end
      end
    end

    let(:instance) { settings.instance }

    describe '#to_hash' do
      it 'returns config as hash' do
        expect(instance.to_hash).to eq({
          bool_true: false,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar',
          },
          private_documents: {
            path: '/documents/private',
            size: 'size_of_private',
            test: [
              'lambda2',
              'lambda1',
            ],
          },
          public_documents: {
            path: '/documents/public',
            size: 'size_of_public',
            test: [
              'lambda2',
              'lambda1',
            ],
          },
          deep: {
            nested: {
              warn_threshold: 100,
              warn_account: 'foo',
            },
          },
          ary: [
            'foo',
            'bar',
          ],
          ary_of_hash: [
            { foo: 'bar' },
            { baz: 'bar' },
          ],
          ary_of_ary: [
            ['foo', 'bar'],
            ['baz', 'bar'],
          ],
          ary_of_mix: [
            ['foo', 'bar'],
            { foo: 'bar' },
          ],
          embedded_ruby: 6,
        })
      end
    end
  end
end
