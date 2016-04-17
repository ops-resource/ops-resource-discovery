name 'ops_resource_storage'
maintainer '${CompanyName} (${CompanyUrl})'
maintainer_email '${EmailDocumentation}'
license 'All rights reserved'
description 'Configures one or more servers as a high availability file server.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '${VersionSemantic}'

depends 'iis'
depends 'webpi'
depends 'windows'
depends 'windows_firewall'
