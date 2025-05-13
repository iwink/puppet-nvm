require 'spec_helper'

describe 'nvm::npm', :type => :define do
  let(:title) { 'less--nodejs--18.20.4' }
  let(:pre_condition) { [
      'class { "nvm": user => "foo" } nvm::node::install { "18.20.4": user => "foo", set_default => false, nvm_dir => "/nvm_dir" }'
  ] }

  context 'with ensure => present' do
    let :params do
    {
      :nvm_dir    => '/nvm_dir',
      :nodejs_version => '18.20.4',
      :user       => 'foo',
      :ensure     => 'present',
    }
    end

    it { should contain_exec('npm install less') }
  end

end
