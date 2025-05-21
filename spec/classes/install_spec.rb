require 'spec_helper'

describe 'nvm::install', type: :class do
  let(:pre_condition) do
    [
      'file { "dependencies": ensure => directory }',
    ]
  end

  context 'with refectch => false' do
    let :params do
      {
        user: 'foo',
        home: '/home/foo',
        version: 'version',
        nvm_dir: 'nvm_dir',
        nvm_repo: 'nvm_repo',
        dependencies: ['File[dependencies]'],
        refetch: false
      }
    end

    it {
      is_expected.to contain_exec('git clone nvm_repo nvm_dir')
        .with_command('git clone nvm_repo nvm_dir')
        .with_user('foo')
        .with_cwd('/home/foo')
        .with_unless('/usr/bin/test -d nvm_dir/.git')
        .that_notifies('Exec[git checkout nvm_repo version]')
    }
    it { is_expected.not_to contain_exec('git fetch nvm_repo nvm_dir') }
    it {
      is_expected.to contain_exec('git checkout nvm_repo version')
        .with_command('git checkout --quiet version')
        .with_user('foo')
        .with_cwd('nvm_dir')
        .with_refreshonly(true)
    }
  end

  context 'with refetch => true' do
    let :params do
      {
        user: 'foo',
        home: '/home/foo',
        version: 'version',
        nvm_dir: 'nvm_dir',
        nvm_repo: 'nvm_repo',
        dependencies: ['File[dependencies]'],
        refetch: true
      }
    end

    it {
      is_expected.to contain_exec('git clone nvm_repo nvm_dir')
        .with_command('git clone nvm_repo nvm_dir')
        .with_user('foo')
        .with_cwd('/home/foo')
        .with_unless('/usr/bin/test -d nvm_dir/.git')
        .that_notifies('Exec[git checkout nvm_repo version]')
    }
    it {
      is_expected.to contain_exec('git fetch nvm_repo nvm_dir')
        .with_command('git fetch')
        .with_cwd('nvm_dir')
        .with_user('foo')
        .with_require('Exec[git clone nvm_repo nvm_dir]')
        .that_notifies('Exec[git checkout nvm_repo version]')
    }
    it {
      is_expected.to contain_exec('git checkout nvm_repo version')
        .with_command('git checkout --quiet version')
        .with_user('foo')
        .with_cwd('nvm_dir')
        .with_refreshonly(true)
    }
  end

  context 'without required param user' do
    it { expect { catalogue }.to raise_error }
  end
end
