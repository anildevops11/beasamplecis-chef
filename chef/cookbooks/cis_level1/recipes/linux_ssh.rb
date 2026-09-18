#
# Cookbook:: cis_level1
# Recipe:: linux_ssh
# CIS chapter 5.2.x — SSH daemon hardening, exception-aware via data bag
#

exceptions = begin
  data_bag_item('cis_exceptions', 'ssh_root_login')
rescue
  nil
end
exempt = exceptions && exceptions['exempt_nodes'].include?(node.name)

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables(
    permit_root_login: exempt ? 'yes' : node['cis']['linux']['ssh']['permit_root_login'],
    max_auth_tries: node['cis']['linux']['ssh']['max_auth_tries'],
    client_alive_interval: node['cis']['linux']['ssh']['client_alive_interval'],
    client_alive_count_max: node['cis']['linux']['ssh']['client_alive_count_max']
  )
  notifies :reload, 'service[sshd]', :delayed
end

service 'sshd' do
  action [:enable, :start]
end
