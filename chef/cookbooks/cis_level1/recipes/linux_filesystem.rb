#
# Cookbook:: cis_level1
# Recipe:: linux_filesystem
# CIS chapter 1.1.x — disable unused filesystem modules, harden /tmp mount
#

%w(cramfs freevxfs jffs2 hfs hfsplus udf).each do |fs|
  file "/etc/modprobe.d/cis-#{fs}.conf" do
    content "install #{fs} /bin/true\n"
    owner 'root'
    group 'root'
    mode '0644'
  end
end

mount '/tmp' do
  device 'tmpfs'
  fstype 'tmpfs'
  options 'defaults,rw,nosuid,nodev,noexec,relatime'
  action [:mount, :enable]
  only_if { ::File.exist?('/etc/fstab') }
end
