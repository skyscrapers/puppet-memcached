##### LICENSE

# Copyright (c) Skyscrapers (iLibris bvba) 2014 - http://skyscrape.rs
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

##### PARAMETERS WITH DEFAULTS

# $listenaddress = '0.0.0.0'
# $listenport    = '11211'
# $memorycap     = '64'
# to manage your own config file set this to true, all other parameteres will be ignored
# $customconfig  = false
#
# USAGE
#
# class {'memcached': }
# class {'memcached': listenaddress => '0.0.0.0', listenport => '11211', memorycap => '64', customconfig => false, }

class memcached ($listenaddress = $memcached::params::listenaddress,
                 $listenport    = $memcached::params::listenport,
                 $memorycap     = $memcached::params::memorycap,
                 $customconfig  = $memcached::params::customconfig) inherits memcached::params {

  class { '::memcached::install': } ->
  class { '::memcached::config': } ~>
  class { '::memcached::service': }

}
