#
# Cookbook:: cis_level1
# Recipe:: windows_rdp
# CIS chapter 18.9.x — RDP default-deny + minimum encryption level
#

registry_key 'HKLM\\System\\CurrentControlSet\\Control\\Terminal Server' do
  values [{
    name: 'fDenyTSConnections',
    type: :dword,
    data: node['cis']['windows']['rdp']['deny'] ? 1 : 0
  }]
  action :create
end

registry_key 'HKLM\\System\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp' do
  values [{
    name: 'MinEncryptionLevel',
    type: :dword,
    data: 3
  }]
  action :create
end
