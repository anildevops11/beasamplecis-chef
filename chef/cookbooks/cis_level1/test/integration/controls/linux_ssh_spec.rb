control 'cis-5.2.11' do
  impact 0.5
  title 'Ensure SSH MaxAuthTries is configured'
  desc 'Limits the number of failed authentication attempts per connection.'
  only_if('skip on windows') { os.linux? }

  describe sshd_config do
    its('MaxAuthTries') { should cmp <= 4 }
    its('PermitRootLogin') { should eq 'no' }
    its('PermitEmptyPasswords') { should eq 'no' }
  end
end

control 'custom-1.1.2.1' do
  impact 0.7
  title 'Ensure /tmp is mounted with noexec,nosuid,nodev'
  desc 'Prevents execution of binaries from /tmp, a common post-exploitation technique.'
  only_if('skip on windows') { os.linux? }

  describe mount('/tmp') do
    it { should be_mounted }
    its('options') { should include 'noexec' }
    its('options') { should include 'nosuid' }
    its('options') { should include 'nodev' }
  end
end
