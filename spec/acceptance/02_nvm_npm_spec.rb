require 'spec_helper_acceptance'

describe 'nvm::npm define' do
  describe 'install local package' do
    pp = <<-EOS
        class { 'nvm':
            user        => 'foo',
            manage_user => true,
        }

        nvm::node::install { '18.20.4':
            user        => 'foo',
        }
        file { '/nodejs':
            ensure => directory,
            owner  => 'foo',
            group  => 'foo',
            mode   => '0755',
        }
        nvm::npm { 'less--nodejs--18.20.4':
          ensure     => 'present',
          package    => 'less',
          user       => 'foo',
          target     => '/nodejs',
          nodejs_version => '18.20.4',
        }
    EOS
    let(:manifest) { pp }

    it 'works with no errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end
    describe file('/nodejs/node_modules/less/bin/lessc') do
      it { is_expected.to exist }
    end
  end

  describe 'install global package' do
    pp = <<-EOS
        class { 'nvm':
            user        => 'root',
            manage_user => true,
        }

        nvm::node::install { '18.20.4':
            user        => 'root',
        }
        file { '/nodejs':
            ensure => directory,
            owner  => 'foo',
            group  => 'foo',
            mode   => '0755',
        }
        nvm::npm { 'less--nodejs--18.20.4':
          ensure     => 'present',
          package    => 'less',
          user       => 'root',
          install_options => ['--global'],
          nodejs_version => '18.20.4',
        }
    EOS
    let(:manifest) { pp }

    it 'works with no errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end

    describe file('/root/.nvm/versions/node/v18.20.4/bin/lessc') do
      it { is_expected.to exist }
    end
  end
end
