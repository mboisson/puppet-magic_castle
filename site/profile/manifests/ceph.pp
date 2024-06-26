type CephFS = Struct[
  {
    'share_name' => String,
    'access_key' => String,
    'export_path' => String,
    'mount_binds' => Optional[Array[Variant[Tuple[String, String], Tuple[String,String,String]]]],
    'binds_fcontext_equivalence' => Optional[String],
  }
]

class profile::ceph::client (
  Array[String] $mon_host,
  Hash[String, CephFS] $shares,
) {
  require profile::ceph::client::install

  $mon_host_string = join($mon_host, ',')
  $ceph_conf = @("EOT")
    [client]
    client quota = true
    mon host = ${mon_host_string}
    | EOT

  file { '/etc/ceph/ceph.conf':
    content => $ceph_conf,
  }

  ensure_resources(profile::ceph::client::share, $shares, { 'mon_host' => $mon_host, 'mount_binds' => [] })
}

class profile::ceph::client::install {
  include epel

  yumrepo { 'ceph-stable':
    ensure        => present,
    enabled       => true,
    baseurl       => "https://download.ceph.com/rpm-nautilus/el${$::facts['os']['release']['major']}/${::facts['architecture']}/",
    gpgcheck      => 1,
    gpgkey        => 'https://download.ceph.com/keys/release.asc',
    repo_gpgcheck => 0,
  }

  if versioncmp($::facts['os']['release']['major'], '8') >= 0 {
    $argparse_pkgname = 'python3-ceph-argparse'
  } else {
    $argparse_pkgname = 'python-ceph-argparse'
  }

  package {
    [
      'libcephfs2',
      'python-cephfs',
      'ceph-common',
      $argparse_pkgname,
      # 'ceph-fuse',
    ]:
      ensure  => installed,
      require => [Yumrepo['epel'], Yumrepo['ceph-stable']],
  }
}

define profile::ceph::client::share (
  String $share_name,
  Array[String] $mon_host,
  String $access_key,
  String $export_path,
  Array[Variant[Tuple[String, String], Tuple[String,String,String]]] $mount_binds,
  Optional[String] $binds_fcontext_equivalence = undef,
) {
  $client_fullkey = @("EOT")
    [client.${name}]
    key = ${access_key}
    | EOT

  file { "/etc/ceph/client.fullkey.${name}":
    content => $client_fullkey,
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
  }

  file { "/etc/ceph/client.keyonly.${name}":
    content => Sensitive($access_key),
    mode    => '0600',
    owner   => 'root',
    group   => 'root',
  }
  file { "/mnt/${name}":
    ensure => directory,
  }

  $mon_host_string = join($mon_host, ',')
  mount { "/mnt/${name}":
    ensure  => 'mounted',
    fstype  => 'ceph',
    device  => "${mon_host_string}:${export_path}",
    options => "name=${share_name},secretfile=/etc/ceph/client.keyonly.${name}",
    require => File['/etc/ceph/ceph.conf'],
  }

  $mount_binds.each |$tuple| {
    $src = $tuple[0]
    $dst = $tuple[1]
    if length($tuple) > 2 {
      $mount_type = $tuple[2]
    }
    else {
      $mount_type = directory
    }

    file { "/${dst}":
      ensure  => $mount_type,
    }
    mount { "/${dst}":
      ensure  => 'mounted',
      fstype  => 'none',
      options => 'rw,bind',
      device  => "/mnt/${name}/${src}",
      require => [
        File["/${dst}"],
        Mount["/mnt/${name}"]
      ],
    }

    if ($binds_fcontext_equivalence and $binds_fcontext_equivalence != "/${dst}") {
      selinux::fcontext::equivalence { "/${dst}":
        ensure  => 'present',
        target  => $binds_fcontext_equivalence,
        require => Mount["/${dst}"],
      }
    }
  }
}
