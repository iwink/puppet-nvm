require 'spec_helper_acceptance'

describe 'nvm::node::install define' do
  describe 'running puppet code' do
    pp = <<-EOS
        class { 'nvm':
            user        => 'foo',
            manage_user => true,
        }

        nvm::node::install { '4.3.1':
            user        => 'foo',
            set_default => true,
        }

        nvm::node::install { '18.20.4':
            user    => 'foo',
            version_alias   => 'bar',
        }
    EOS
    let(:manifest) { pp }

    it 'works with no errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end

    describe command('su - foo -c ". /home/foo/.nvm/nvm.sh && nvm --version" -s /bin/bash') do
      its('exit_status') { is_expected.to eq 0 }
      its('stdout') { is_expected.to match(%r{0.40.3}) }
    end

    describe command('su - foo -c ". /home/foo/.nvm/nvm.sh && node --version" -s /bin/bash') do
      its('exit_status') { is_expected.to eq 0 }
      its('stdout') { is_expected.to match(%r{4.3.1}) }
    end

    describe command('su - foo -c ". /home/foo/.nvm/nvm.sh && nvm ls" -s /bin/bash') do
      its('exit_status') { is_expected.to eq 0 }
      its('stdout') { is_expected.to match(%r{18.20.4}) }
    end

    describe file('/home/foo/.nvm/alias/bar') do
      it { is_expected.to exist }
      it { is_expected.to be_file }
      it { is_expected.to contain '18.20.4' }
    end
  end
end
