default['cis']['level'] = 1

# Linux
default['cis']['linux']['ssh']['max_auth_tries'] = 4
default['cis']['linux']['ssh']['permit_root_login'] = 'no'
default['cis']['linux']['ssh']['client_alive_interval'] = 300
default['cis']['linux']['ssh']['client_alive_count_max'] = 0
default['cis']['linux']['password']['max_days'] = 365
default['cis']['linux']['password']['min_days'] = 7
default['cis']['linux']['password']['warn_age'] = 7
default['cis']['linux']['auditd']['enabled'] = true

# Windows
default['cis']['windows']['password']['min_length'] = 14
default['cis']['windows']['password']['complexity'] = 1
default['cis']['windows']['lockout']['threshold'] = 5
default['cis']['windows']['lockout']['duration'] = 15
default['cis']['windows']['rdp']['deny'] = true
