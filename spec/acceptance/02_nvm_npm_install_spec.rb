require 'spec_helper_acceptance'

describe 'nvm::npm define' do

  describe 'running puppet code' do
    pp = <<-EOS
        class { 'nvm':
            user        => 'foo',
            manage_user => true,
        }

        nvm::node::install { '18.20.4':
            user        => 'foo',
            set_default => true,
        }

        nvm::npm { 'less--nodejs--18.20.4':
          ensure     => 'present',
          user       => 'foo',
          nvm_dir    => '/home/foo/.nvm',
          nodejs_version => '18.20.4',
        }
    EOS
    let(:manifest) { pp }

    it 'should work with no errors' do
      apply_manifest(manifest, :catch_failures => true)
    end

    it 'should be idempotent' do
      apply_manifest(manifest, :catch_changes => true)
    end

  end

end
