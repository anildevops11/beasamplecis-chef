#
# Cookbook:: cis_level1
# Recipe:: linux_sysctl
# CIS chapter 3.x — kernel network parameter hardening
#

cis_sysctl_settings = {
  'net.ipv4.ip_forward' => 0,
  'net.ipv4.conf.all.send_redirects' => 0,
  'net.ipv4.conf.default.send_redirects' => 0,
  'net.ipv4.conf.all.accept_source_route' => 0,
  'net.ipv4.conf.all.accept_redirects' => 0,
  'net.ipv4.conf.all.secure_redirects' => 0,
  'net.ipv4.conf.all.log_martians' => 1,
  'net.ipv4.icmp_echo_ignore_broadcasts' => 1,
  'net.ipv4.icmp_ignore_bogus_error_responses' => 1,
  'net.ipv4.conf.all.rp_filter' => 1,
  'net.ipv4.tcp_syncookies' => 1,
  'kernel.randomize_va_space' => 2
}

cis_sysctl_settings.each do |key, value|
  sysctl key do
    value value
  end
end
