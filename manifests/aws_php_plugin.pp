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

  # TODO
  # validate($version)
  # validate($arch)
  # validate($php_version)

  file {
    '/tmp/AwsElasticCacheClusterClient.tgz':
      ensure  => file,
      content => "puppet:///modules/memcached/tmp/AmazonElasticCacheClusterClient-${$version}-${$php_version}-${$arch}.tgz",
      mode    => '0644',
      owner   => root,
      group   => root,
      notify  => Exec['pecl_install_memcached'];
  }

  php::extension { '/tmp/AwsElasticCacheClusterClient.tgz':
    ensure => 'installed',
    provider => 'pecl'
  }
  # exec { 'pecl_install_memcached':
  #   command => '/usr/bin/pecl install /tmp/AwsElasticCacheClusterClient.tgz',
  #   require => Package['pecl'],
  #   notify  => Service['php5-fpm']
  # }

}
