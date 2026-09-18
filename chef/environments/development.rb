name 'development'
description 'Development environment — CIS Level 1 still applies, but exceptions are easier to add for rapid iteration'

default_attributes(
  'cis' => {
    'level' => 1
  }
)

cookbook_versions(
  'cis_level1' => '>= 0.1.0'
)
