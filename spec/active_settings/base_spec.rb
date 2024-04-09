require 'spec_helper'

RSpec.describe ActiveSettings::Base do

  context 'when source file is nil' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
      end
    end

    let(:instance) { settings.instance }

    it 'should raise an error' do
      expect {
        instance
      }.to raise_error(ActiveSettings::Error::SourceFileNotDefinedError)
    end
  end

  context 'without namespace' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source get_fixture_path('settings.yml')
      end
    end

    let(:instance) { settings.instance }

    describe '#source' do
      it 'should delegate to class method' do
        expect(instance.source).to eq get_fixture_path('settings.yml')
      end
    end

    describe '#namespace' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source get_fixture_path('settings.yml')
          namespace 'foo'
        end
      end

      let(:instance) { settings.instance }

      it 'should delegate to class method' do
        expect(instance.namespace).to eq 'foo'
      end
    end

    describe 'settings accesors' do
      it 'should access settings by method' do
        expect(instance.foo).to eq 'bar'
      end

      it 'should access nested settings by method' do
        expect(instance.nested.foo).to eq 'bar'
      end

      it 'should access settings by string key' do
        expect(instance['foo']).to eq 'bar'
      end

      it 'should access nested settings by string key' do
        expect(instance['nested']['foo']).to eq 'bar'
      end

      it 'should access settings by symbol key' do
        expect(instance[:foo]).to eq 'bar'
      end

      it 'should access nested settings by symbol key' do
        expect(instance[:nested][:foo]).to eq 'bar'
      end
    end

    describe '#key?' do
      context 'when string key exist' do
        it 'should return true' do
          expect(instance.key?('foo')).to be true
        end
      end

      context 'when string key dont exist' do
        it 'should return false' do
          expect(instance.key?('bar')).to be false
        end
      end

      context 'when symbol key exist' do
        it 'should return true' do
          expect(instance.key?(:foo)).to be true
        end
      end

      context 'when symbol key dont exist' do
        it 'should return false' do
          expect(instance.key?(:bar)).to be false
        end
      end

      context 'when nested string key exist' do
        it 'should return true' do
          expect(instance.nested.key?('foo')).to be true
        end
      end

      context 'when nested string key dont exist' do
        it 'should return false' do
          expect(instance.nested.key?('bar')).to be false
        end
      end

      context 'when nested symbol key exist' do
        it 'should return true' do
          expect(instance.nested.key?(:foo)).to be true
        end
      end

      context 'when nested symbol key dont exist' do
        it 'should return false' do
          expect(instance.nested.key?(:bar)).to be false
        end
      end
    end

    describe '#fetch' do
      context 'when string key exist' do
        it 'should return value' do
          expect(instance.fetch('foo')).to eq 'bar'
        end
      end

      context 'when string key dont exist' do
        it 'should return nil' do
          expect(instance.fetch('bar')).to be nil
        end
      end

      context 'when symbol key exist' do
        it 'should return value' do
          expect(instance.fetch(:foo)).to eq 'bar'
        end
      end

      context 'when symbol key dont exist' do
        it 'should return nil' do
          expect(instance.fetch(:bar)).to be nil
        end
      end

      context 'when nested string key exist' do
        it 'should return value' do
          expect(instance.nested.fetch('foo')).to eq 'bar'
        end
      end

      context 'when nested string key dont exist' do
        it 'should return nil' do
          expect(instance.nested.fetch('bar')).to be nil
        end
      end

      context 'when nested symbol key exist' do
        it 'should return value' do
          expect(instance.nested.fetch(:foo)).to eq 'bar'
        end
      end

      context 'when nested symbol key dont exist' do
        it 'should return nil' do
          expect(instance.nested.fetch(:bar)).to be nil
        end
      end

      context 'when key dont exist and a default value is given' do
        it 'should return default value' do
          expect(instance.fetch(:path, 'foo')).to eq 'foo'
        end
      end

      context 'when key dont exist and a block is given' do
        it 'should yield block' do
          expect(instance.fetch(:path){ 'foo' }).to eq 'foo'
        end
      end
    end

    describe '#dig' do
      context 'when nested string key exist' do
        it 'should return value' do
          expect(instance.dig('nested', 'foo')).to eq 'bar'
        end
      end

      context 'when nested string key dont exist' do
        it 'should return nil' do
          expect(instance.dig('nested', 'bar')).to be nil
        end
      end

      context 'when nested symbol key exist' do
        it 'should return value' do
          expect(instance.dig(:nested, :foo)).to eq 'bar'
        end
      end

      context 'when nested symbol key dont exist' do
        it 'should return nil' do
          expect(instance.dig(:nested, :bar)).to be nil
        end
      end
    end

    describe '#each' do
      it 'should iterate on Settings' do
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
          embedded_ruby: 6
        })
      end
    end

    describe '#to_hash' do
      it 'should return config as hash' do
        expect(instance.to_hash).to eq({
          bool_true: true,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar'
          },
          deep: {
            nested: {
              warn_threshold: 100,
            }
          },
          ary: [
            'foo',
            'bar'
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
          embedded_ruby: 6
        })
      end
    end

    describe '#to_json' do
      it 'should return config as json' do
        expect(instance.to_json).to eq '{"bool_true":true,"bool_false":false,"string":"foo","integer":1,"float":1.0,"foo":"bar","nested":{"foo":"bar"},"deep":{"nested":{"warn_threshold":100}},"ary":["foo","bar"],"ary_of_hash":[{"foo":"bar"},{"baz":"bar"}],"ary_of_ary":[["foo","bar"],["baz","bar"]],"ary_of_mix":[["foo","bar"],{"foo":"bar"}],"embedded_ruby":6}'
        expect(instance.send(:to_json)).to eq '{"bool_true":true,"bool_false":false,"string":"foo","integer":1,"float":1.0,"foo":"bar","nested":{"foo":"bar"},"deep":{"nested":{"warn_threshold":100}},"ary":["foo","bar"],"ary_of_hash":[{"foo":"bar"},{"baz":"bar"}],"ary_of_ary":[["foo","bar"],["baz","bar"]],"ary_of_mix":[["foo","bar"],{"foo":"bar"}],"embedded_ruby":6}'
      end
    end

    describe '.fail_on_missing' do
      context 'when fail_on_missing is false' do
        it 'should not raise error when accessing missing key' do
          expect {
            instance.path
          }.to_not raise_error
        end

        it 'should not raise error when accessing missing nested key' do
          expect {
            instance.nested.path
          }.to_not raise_error
        end

        it 'should return nil when accessing missing nested key' do
          expect(instance.nested.path).to be nil
        end
      end

      context 'when fail_on_missing is true' do
        before { ActiveSettings.fail_on_missing = true }
        after  { ActiveSettings.fail_on_missing = false }

        it 'should raise error when accessing missing key' do
          expect {
            instance.path
          }.to raise_error(KeyError).with_message('key not found: :path')
        end

        it 'should raise error when accessing nested missing key' do
          expect {
            instance.nested.path
          }.to raise_error(KeyError).with_message('key not found: :path')
        end
      end
    end

    describe '#merge' do
      it 'should merge hash' do
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
            }
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
          embedded_ruby: 6
        })
      end

      it 'should merge nested hash' do
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
            }
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
          embedded_ruby: 6
        })
      end

      context 'when overwrite_arrays is true (default)' do
        it 'should merge/overwrite nested ary' do
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
              }
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
            embedded_ruby: 6
          })
        end

        it 'should merge/overwrite nested ary of hash' do
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
              }
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
            embedded_ruby: 6
          })
        end

        it 'should merge/overwrite nested ary of ary' do
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
              }
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
            embedded_ruby: 6
          })
        end
      end

      context 'when overwrite_arrays is false' do
        before { ActiveSettings.overwrite_arrays = false }
        after  { ActiveSettings.overwrite_arrays = true }

        it 'should merge/extend nested ary' do
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
              }
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
            embedded_ruby: 6
          })
        end

        it 'should merge/extend nested ary of hash' do
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
              }
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
            embedded_ruby: 6
          })
        end

        it 'should merge/extend nested ary of ary' do
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
              }
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
            embedded_ruby: 6
          })
        end
      end
    end

    describe '#validate!' do
      context 'when schema is not defined' do
        it 'should do nothing' do
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
          it 'should validate settings' do
            expect {
             with_valid_schema.instance.validate!
            }.to_not raise_error
          end
        end

        context 'when schema is invalid' do
          it 'should validate settings' do
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
        hash.each do |k, v|
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

          it 'should load settings from env vars' do
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
                }
              },
              ary: [
                'foo',
                'bar'
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
              embedded_ruby: 6
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

          it 'should load settings from env vars' do
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
                }
              },
              ary: [
                'foo',
                'bar'
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
              embedded_ruby: 6
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

        it 'should load settings from env vars' do
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
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
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

        it 'should load settings from env vars' do
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
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
          })
        end
      end

      context 'when ENV is empty' do
        before do
          ActiveSettings.use_env = true
          @old_env = ENV.to_hash
          ENV.clear
        end

        after do
          ActiveSettings.use_env = false
          ENV.update(@old_env)
        end

        it 'should load settings from env vars' do
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
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
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

        it 'should raise error' do
          expect {
            instance.to_hash
          }.to raise_error(ActiveSettings::Error::EnvPrefixNotDefinedError)
        end
      end
    end
  end

  context 'with namespace' do
    context 'when namespace is development' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source    get_fixture_path('settings_with_namespace.yml')
          namespace 'development'
        end
      end

      let(:instance) { settings.instance }

      describe '#to_hash' do
        it 'should return config as hash' do
          expect(instance.to_hash).to eq({
            bool_true: true,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'baz',
            nested: {
              foo: 'bar'
            },
            deep: {
              nested: {
                warn_threshold: 50,
                warn_account: 'foo'
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
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

        it 'should load settings from env vars' do
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
                warn_account: 'bar'
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
          })
        end
      end
    end

    context 'when namespace is production' do
      let(:settings) do
        Class.new(ActiveSettings::Base) do
          source    get_fixture_path('settings_with_namespace.yml')
          namespace 'production'

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
        it 'should return config as hash' do
          expect(instance.to_hash).to eq({
            bool_true: false,
            bool_false: false,
            string: 'foo',
            integer: 1,
            float: 1.0,
            foo: 'bar',
            nested: {
              foo: 'bar'
            },
            deep: {
              nested: {
                warn_threshold: 100,
                warn_account: 'foo',
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
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

        it 'should load settings from env vars' do
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
                warn_account: 'bar'
              }
            },
            ary: [
              'foo',
              'bar'
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
            embedded_ruby: 6
          })
        end
      end
    end
  end

  context 'with custom settings' do
    let(:settings) do
      Class.new(ActiveSettings::Base) do
        source    get_fixture_path('settings_with_namespace.yml')
        namespace 'production'

        def after_initialize!
          super
          load_storage_config!
        end

        def load_storage_config!
          hash = {}
          %w[private public].each do |prefix|
            hash["#{prefix}_documents"] = {}
            hash["#{prefix}_documents"]['path'] = "/documents/#{prefix}"
            hash["#{prefix}_documents"]['size'] = -> { "size_of_#{prefix}" }
            hash["#{prefix}_documents"]['test'] = [-> { "lambda2" }, -> { "lambda1" }]
          end
          merge!(hash)
        end
      end
    end

    let(:instance) { settings.instance }

    describe '#to_hash' do
      it 'should return config as hash' do
        expect(instance.to_hash).to eq({
          bool_true: false,
          bool_false: false,
          string: 'foo',
          integer: 1,
          float: 1.0,
          foo: 'bar',
          nested: {
            foo: 'bar'
          },
          private_documents: {
            path: '/documents/private',
            size: 'size_of_private',
            test: [
              'lambda2',
              'lambda1',
            ]
          },
          public_documents: {
            path: '/documents/public',
            size: 'size_of_public',
            test: [
              'lambda2',
              'lambda1',
            ]
          },
          deep: {
            nested: {
              warn_threshold: 100,
              warn_account: 'foo',
            }
          },
          ary: [
            'foo',
            'bar'
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
          embedded_ruby: 6
        })
      end
    end
  end
end
