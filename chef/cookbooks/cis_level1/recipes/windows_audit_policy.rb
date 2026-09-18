#
# Cookbook:: cis_level1
# Recipe:: windows_audit_policy
# CIS chapter 17.x — advanced audit policy subcategories
#

cis_audit_subcategories = [
  'Logon', 'Logoff', 'Account Lockout', 'Special Logon',
  'Sensitive Privilege Use', 'Security State Change',
  'Security System Extension', 'System Integrity'
]

cis_audit_subcategories.each do |subcat|
  powershell_script "audit_policy_#{subcat}" do
    code "auditpol /set /subcategory:\"#{subcat}\" /success:enable /failure:enable"
    not_if "auditpol /get /subcategory:\"#{subcat}\" | Select-String 'Success and Failure'"
  end
end
