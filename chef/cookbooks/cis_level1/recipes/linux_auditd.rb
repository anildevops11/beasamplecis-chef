#
# Cookbook:: cis_level1
# Recipe:: linux_auditd
# CIS chapter 4.1.x — auditd installation and rule set
#

package 'auditd' do
  only_if { node['cis']['linux']['auditd']['enabled'] }
end

template '/etc/audit/rules.d/cis.rules' do
  source 'audit.rules.erb'
  mode '0640'
  notifies :restart, 'service[auditd]', :delayed
  only_if { node['cis']['linux']['auditd']['enabled'] }
end

service 'auditd' do
  action [:enable, :start]
  only_if { node['cis']['linux']['auditd']['enabled'] }
end
