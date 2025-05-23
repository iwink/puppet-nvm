require 'spec_helper'

describe 'nvm::node::install', type: :define do
  let(:title) { '0.12.7' }
  let(:pre_condition) do
    [
      'class { "nvm": user => "foo" }',
    ]
  end

  context 'with set_default => false' do
    let :params do
      {
        user: 'foo',
        nvm_dir: '/nvm_dir',
        set_default: false,
      }
    end

    it {
      is_expected.to contain_exec('nvm install node version v0.12.7')
        .with_cwd('/nvm_dir')
        .with_command('. /nvm_dir/nvm.sh && nvm install  v0.12.7')
        .with_user('foo')
        .with_unless('. /nvm_dir/nvm.sh && nvm which v0.12.7')
        .that_requires('Class[nvm::install]')
        .with_provider('shell')
    }
    it { is_expected.not_to contain_exec('nvm set node version v0.12.7 as default') }
  end

  context 'with set_default => true' do
    let :params do
      {
        user: 'foo',
        nvm_dir: '/nvm_dir',
        set_default: true,
      }
    end

    it {
      is_expected.to contain_exec('nvm install node version v0.12.7')
        .with_cwd('/nvm_dir')
        .with_command('. /nvm_dir/nvm.sh && nvm install  v0.12.7')
        .with_user('foo')
        .with_unless('. /nvm_dir/nvm.sh && nvm which v0.12.7')
        .that_requires('Class[nvm::install]')
        .with_provider('shell')
    }
    it {
      is_expected.to contain_exec('nvm set node version v0.12.7 as default')
        .with_cwd('/nvm_dir')
        .with_command('. /nvm_dir/nvm.sh && nvm alias default v0.12.7')
        .with_user('foo')
        .with_unless('. /nvm_dir/nvm.sh && nvm which default | grep v0.12.7')
        .with_provider('shell')
    }
  end

  context 'with from_source => true' do
    let :params do
      {
        user: 'foo',
        nvm_dir: '/nvm_dir',
        from_source: true
      }
    end

    it {
      is_expected.to contain_exec('nvm install node version v0.12.7')
        .with_cwd('/nvm_dir')
        .with_command('. /nvm_dir/nvm.sh && nvm install  -s  v0.12.7')
        .with_user('foo')
        .with_unless('. /nvm_dir/nvm.sh && nvm which v0.12.7')
        .that_requires('Class[nvm::install]')
        .with_provider('shell')
    }
    it { is_expected.not_to contain_exec('nvm set node version v0.12.7 as default') }
  end

  context 'without required param user' do
    it { expect { catalogue }.to raise_error }
  end

  context 'with alias => bar' do
    let :params do
      {
        user: 'foo',
        nvm_dir: '/nvm_dir',
        version_alias: 'bar',
      }
    end

    it {
      is_expected.to contain_exec('nvm set node version v0.12.7 alias as bar')
        .with_cwd('/nvm_dir')
        .with_command('. /nvm_dir/nvm.sh && nvm alias bar v0.12.7')
        .with_user('foo')
        .with_unless('. /nvm_dir/nvm.sh && nvm which bar | grep v0.12.7')
        .with_provider('shell')
    }
  end
end
