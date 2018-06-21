control 'nrpe_installed' do
  title 'NRPE should be installed.'
  describe service('nrpe') do
    it { should be_installed }
    it { should be_enabled }
    it { should be_running }
  end
end

control 'nrpe_installed' do
  title 'NRPE should be correctly configured.'
  describe ini('/etc/nagios/nrpe.cfg') do
  its('pid_file') { should eq '/var/run/nagios/nrpe.pid' }
  its('server_port') { should eq '5666' }
  its('nrpe_user') { should eq 'nrpe' }
  its('nrpe_group') { should eq 'nrpe' }
  its('include_dir') { should eq '/etc/nrpe.d/' }
end
