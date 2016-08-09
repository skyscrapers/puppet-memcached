##### LICENSE

# Copyright (c) Skyscrapers (iLibris bvba) 2016 - http://skyscrape.rs
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

class memcached::aws_php_plugin (
  $php_version = undef
) {

  $version = '1.0.1'
  $arch = $::architecture ? {
    'x86_64' => '64bit',
    'amd64' => '64bit',
    /i\d86/ => '32bit',
    default => false
  }

  $oldphp = defined(Class['oldphp'])

  if $oldphp and !defined(Class['php::params']) {
    include ::php::params
  }

  # TODO
  # validate($version)
  # validate($arch)
  # validate($php_version)

  file {
    '/tmp/AwsElasticCacheClusterClient.tgz':
      ensure  => file,
      source  => "puppet:///modules/memcached/tmp/AmazonElastiCacheClusterClient-${$version}-${$php_version}-${$arch}.tgz",
      mode    => '0644',
      owner   => root,
      group   => root;
  }

  exec { 'pecl_install_memcached':
    command => '/usr/bin/pecl install /tmp/AwsElasticCacheClusterClient.tgz',
    require => $oldphp ? {
      true => [
        Package['php-pear'],
        Package['php5-dev'],
        File['/tmp/AwsElasticCacheClusterClient.tgz']
      ],
      false => [
        Class['::php::pear'],
        Class['::php::dev'],
        File['/tmp/AwsElasticCacheClusterClient.tgz']
      ]
    }
  }

  if $oldphp {
    $config_root_ini = '/etc/php5/mods-available'
  } else {
    $config_root_ini = pick_default($::php::config_root_ini, $::php::params::config_root_ini)
  }

  ::php::config { 'memcached':
    file    => "${config_root_ini}/memcached.ini",
    config  => {
      'extension' => 'amazon-elasticache-cluster-client.so'
    },
    require => Exec['pecl_install_memcached'],
  }

  # Ubuntu/Debian systems use the mods-available folder. We need to enable
  # settings files ourselves with php5enmod command.
  $ext_tool_enable   = pick_default($::php::ext_tool_enable, $::php::params::ext_tool_enable)
  $ext_tool_query    = pick_default($::php::ext_tool_query, $::php::params::ext_tool_query)

  exec { "${ext_tool_enable} -s ALL memcached":
    onlyif  => "${ext_tool_query} -s cli -m memcached | /bin/grep 'No module matches memcached'",
    require => ::Php::Config['memcached'],
  }


}
