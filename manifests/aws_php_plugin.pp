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

  validate_string($php_version)

  # Take out the dots of the version number to match the package name
  $real_php_version = regsubst($php_version, '\.', '', 'G')

  $version = $real_php_version ? {
    '56' => '1.0.0',
    '70' => '1.0.0',
    default => '1.0.1'
  }

  # Version of the .so file
  $so_version = $real_php_version ? {
    '55' => '1.0.0',
    '56' => '1.0.0',
    default => '1.0.1'
  }

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

  package {
    'php5-memcached':
      ensure => absent
  }

  file {
    '/tmp/AwsElasticCacheClusterClient.tgz':
      ensure  => file,
      source  => "puppet:///modules/memcached/tmp/AmazonElastiCacheClusterClient-${$version}-PHP${$real_php_version}-${$arch}.tgz",
      mode    => '0644',
      owner   => root,
      group   => root;
  }

  if $oldphp {
    exec { 'pecl_install_memcached':
      command => "/bin/tar -xvf /tmp/AwsElasticCacheClusterClient.tgz -C /tmp/ AmazonElastiCacheClusterClient-${$so_version}/amazon-elasticache-cluster-client.so && /bin/mv /tmp/AmazonElastiCacheClusterClient-${$so_version}/amazon-elasticache-cluster-client.so /usr/lib/php5/20121212/amazon-elasticache-cluster-client-${$version}-${$real_php_version}.so",
      require => File['/tmp/AwsElasticCacheClusterClient.tgz'],
      creates => "/usr/lib/php5/20121212/amazon-elasticache-cluster-client-${$version}-${$real_php_version}.so"
    }
  } elsif $real_php_version == '70' {
    # PHP 7.0 has a custom install "method".
    # See: http://docs.aws.amazon.com/AmazonElastiCache/latest/UserGuide/Appendix.PHPAutoDiscoverySetup.html#Appendix.PHPAutoDiscoverySetup.Installing.PHP7x
    exec { 'pecl_install_memcached':
      command => "/bin/tar -xvf /tmp/AwsElasticCacheClusterClient.tgz -C /tmp/ artifact/amazon-elasticache-cluster-client.so && /bin/mv /tmp/artifact/amazon-elasticache-cluster-client.so /usr/lib/php/20151012/amazon-elasticache-cluster-client-${$version}-${$real_php_version}.so",
      require => File['/tmp/AwsElasticCacheClusterClient.tgz'],
      creates => "/usr/lib/php/20151012/amazon-elasticache-cluster-client-${$version}-${$real_php_version}.so"
    }
  } else {
    exec { 'pecl_install_memcached':
      command => '/usr/bin/pecl upgrade /tmp/AwsElasticCacheClusterClient.tgz',
      require => [
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
      'extension' => "amazon-elasticache-cluster-client-${$version}-${$real_php_version}.so"
    },
    require => Exec['pecl_install_memcached'],
  }

  if $oldphp {
    if !defined(Package['php5-common']) {
      package { 'php5-common':
        ensure => installed
      }
    }

    $ext_tool_enable  = '/usr/sbin/php5enmod'
    $ext_tool_query   = '/usr/sbin/php5query'
    $require = [
      ::Php::Config['memcached'],
      Package['php5-common'],
    ]
  } else {
    $ext_tool_enable  = pick_default($::php::ext_tool_enable, $::php::params::ext_tool_enable)
    $ext_tool_query   = pick_default($::php::ext_tool_query, $::php::params::ext_tool_query)
    $require          = ::Php::Config['memcached']
  }

  # Ubuntu/Debian systems use the mods-available folder. We need to enable
  # settings files ourselves with php5enmod command.
  exec { "${ext_tool_enable} -s ALL memcached":
    onlyif  => "${ext_tool_query} -s cli -m memcached | /bin/grep 'No module matches memcached'",
    require => $require,
  }

  if defined(Service['php-fpm']) {
    Exec["${ext_tool_enable} -s ALL memcached"] ~> Service['php-fpm']
  }

  if defined(Service['php5-fpm']) {
    Exec["${ext_tool_enable} -s ALL memcached"] ~> Service['php5-fpm']
  }

}
