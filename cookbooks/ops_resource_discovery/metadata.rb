name 'ops_resource_discovery'
maintainer '${CompanyName} (${CompanyUrl})'
maintainer_email '${EmailDocumentation}'
license 'Apache v2.0'
description 'Configures a resource as a consul server.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '${VersionSemantic}'

depends 'iis'
depends 'webpi'
depends 'windows'
depends 'windows_firewall'
