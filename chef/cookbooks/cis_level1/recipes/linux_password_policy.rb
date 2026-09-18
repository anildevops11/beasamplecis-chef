#
# Cookbook:: cis_level1
# Recipe:: linux_password_policy
# CIS chapters 5.3.x / 5.4.x — PAM password quality + login.defs aging
#

package 'libpam-pwquality' do
  only_if { node['platform_family'] == 'debian' }
end

package 'pam' do
  only_if { %w(rhel fedora).include?(node['platform_family']) }
end

template '/etc/security/pwquality.conf' do
  source 'pwquality.conf.erb'
  mode '0644'
end

template '/etc/login.defs' do
  source 'login.defs.erb'
  mode '0644'
  variables(
    pass_max_days: node['cis']['linux']['password']['max_days'],
    pass_min_days: node['cis']['linux']['password']['min_days'],
    pass_warn_age: node['cis']['linux']['password']['warn_age']
  )
end
