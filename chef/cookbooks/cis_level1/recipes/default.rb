#
# Cookbook:: cis_level1
# Recipe:: default
#
# Entry point — includes OS-specific recipes based on platform_family.
# Always add this cookbook to a run list AFTER any existing server-build
# cookbook (e.g. serverbuild), never before — installing a service can
# re-open a port or reset a config file that hardening already locked down.
#

case node['platform_family']
when 'debian', 'rhel', 'fedora', 'suse'
  include_recipe 'cis_level1::linux_filesystem'
  include_recipe 'cis_level1::linux_ssh'
  include_recipe 'cis_level1::linux_password_policy'
  include_recipe 'cis_level1::linux_auditd'
  include_recipe 'cis_level1::linux_sysctl'
when 'windows'
  include_recipe 'cis_level1::windows_password_policy'
  include_recipe 'cis_level1::windows_rdp'
  include_recipe 'cis_level1::windows_audit_policy'
else
  Chef::Log.warn("cis_level1: no CIS recipes defined for platform_family '#{node['platform_family']}'")
end
