require 'spec_helper_acceptance'

describe 'nvm class' do
  describe 'running puppet code' do
    pp = <<-EOS
      class { 'nvm':
        user           => 'root',
        nvm_dir        => '/opt/nvm',
        version        => 'v0.29.0',
        profile_path   => '/etc/profile.d/nvm.sh',
        install_node   => '0.12.7',
        node_instances => {
          '0.10.36' => {},
          '4.0.0' => {},
        },
      }
    EOS
    let(:manifest) { pp }

    it 'works with no errors' do
      apply_manifest(manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest(manifest, catch_changes: true)
    end

    describe command('. /etc/profile.d/nvm.sh && nvm --version') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{0.29.0}) }
    end

    describe command('. /etc/profile.d/nvm.sh && node --version') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{0.12.7}) }
    end

    describe command('. /etc/profile.d/nvm.sh && nvm ls') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{0.10.36}) }
    end

    describe command('. /etc/profile.d/nvm.sh && nvm ls') do
      its(:exit_status) { is_expected.to eq 0 }
      its(:stdout) { is_expected.to match(%r{4.0.0}) }
    end
  end
end
