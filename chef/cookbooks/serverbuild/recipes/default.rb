#
# Cookbook:: serverbuild
# Recipe:: default
#
# PLACEHOLDER — represents an organization's EXISTING server-build logic
# (installing the application stack, creating service users, etc.).
#
# This file stands in for whatever your real build cookbook already does.
# The only thing that matters for this project is the run-list ordering:
# this cookbook (or its equivalent) must run BEFORE cis_level1, e.g.:
#
#   run_list "recipe[serverbuild]", "recipe[cis_level1]"
#
# Do not merge CIS hardening resources into this file — see the full guide,
# section 2.3, for why they are kept in separate cookbooks.
#

Chef::Log.info('serverbuild: placeholder recipe — replace with your real build logic')
