require 'spec_helper'

describe 'nvm::npm', type: :define do
  let(:title) { 'less--nodejs--18.20.4' }
  let(:pre_condition) do
    [
      'class { "nvm": user => "foo" } nvm::node::install { "18.20.4": user => "foo", set_default => false, nvm_dir => "/nvm_dir" }',
    ]
  end

  context 'with ensure => present' do
    let :params do
      {
        nvm_dir: '/nvm_dir',
        target: '/test',
        nodejs_version: '18.20.4',
        user: 'foo',
        ensure: 'present',
        package: 'less',
      }
    end

    it {
      is_expected.to contain_exec('nvm_18.20.4_npm_install_less')
        .with_command('. /nvm_dir/nvm.sh && nvm use v18.20.4 && npm install less ') # Extra space at the end due to the `options` parameter that is not used
        .with_user('foo')
        .with_cwd('/test')
        .with_unless('. /nvm_dir/nvm.sh && nvm use v18.20.4 && npm  ls --long --parseable | grep less') # Extra space due to global flags
    }
  end
end
