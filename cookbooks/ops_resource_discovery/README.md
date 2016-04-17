ops_resource_storage Cookbook
======================
This cookbook installs the applications and files that should be present on one or more machines that will be used as a high availability file server. 

Requirements
------------

#### cookbooks
- `chef_handler`
- `windows`

Attributes
----------

#### ops_resource_storage::default
<table>
  <tr>
    <th>Key</th>
    <th>Type</th>
    <th>Description</th>
    <th>Default</th>
  </tr>
  <tr>
    <td><tt>['paths']['meta']</tt></td>
    <td>String</td>
    <td>The path to the directory that contains the meta data.</td>
    <td><tt>c:\meta</tt></td>
  </tr>
</table>

Usage
-----
#### ops_resource_storage::default
Just include `ops_resource_storage` in your node's `run_list`:

```json
{
  "name":"my_node",
  "run_list": [
    "recipe[ops_resource_storage]"
  ]
}
```

Contributing
------------
In order to contribute please see contribution guidelines at [github](https://github.com/pvandervelde/ops-resource-storage)

License and Authors
-------------------
Authors: Patrick van der Velde

Licensed under the Apache 2.0 license
