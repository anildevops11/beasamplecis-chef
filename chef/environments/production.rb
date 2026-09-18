name 'production'
description 'Production environment — strict CIS Level 1 enforcement'

default_attributes(
  'cis' => {
    'level' => 1
  }
)

cookbook_versions(
  'cis_level1' => '= 1.0.0'
)
