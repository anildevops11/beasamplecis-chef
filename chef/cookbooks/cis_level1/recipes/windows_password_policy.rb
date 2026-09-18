#
# Cookbook:: cis_level1
# Recipe:: windows_password_policy
# CIS chapters 1.1.x / 1.2.x — local password + lockout policy via secedit
#

template 'C:/Windows/Temp/cis_secpol.inf' do
  source 'secpol.inf.erb'
  variables(
    min_password_length: node['cis']['windows']['password']['min_length'],
    password_complexity: node['cis']['windows']['password']['complexity'],
    lockout_threshold: node['cis']['windows']['lockout']['threshold'],
    lockout_duration: node['cis']['windows']['lockout']['duration']
  )
end

powershell_script 'apply_cis_secpol' do
  code <<-EOH
    secedit /configure /db C:\\Windows\\security\\local.sdb `
      /cfg C:\\Windows\\Temp\\cis_secpol.inf /areas SECURITYPOLICY
  EOH
  action :run
end
