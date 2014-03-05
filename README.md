# OFI

*Introduction here*

## Installation

See [How_to_Install_a_Plugin](http://projects.theforeman.org/projects/foreman/wiki/How_to_Install_a_Plugin)
for how to install Foreman plugins

Simlink `config/ofi.local.rb` to yours Foreman `bundle.d`.

    ln -s ../../OFI/config/ofi.local.rb ofi.local.rb

## Usage

### Dynflow test from console

Assuming that hostgroup is set up with all the necessary information to provision a host, a host provisioning can be triggered using Dynflow form console. E.g.

    ForemanTasks.trigger Actions::Host::Create, 
                         'rhel4', 
                         Hostgroup.find(8), 
                         ComputeResource.find(1)

## TODO

*Todo list here*

## Contributing

Fork and send a Pull Request. Thanks!

## Copyright

Copyright (c) *year* *your name*

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

