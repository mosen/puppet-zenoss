class zenoss::install::deps::repo_remi {

  if $::osfamily == 'RedHat' {
    yumrepo { 'remi':
      descr      => 'Les RPM de remi pour Enterprise Linux $releasever - $basearch',
      mirrorlist => 'http://rpms.famillecollet.com/enterprise/$releasever/remi/mirror',
      enabled    => 1,
      protect    => 0,
      gpgcheck   => 1,
      gpgkey     => "http://rpms.famillecollet.com/RPM-GPG-KEY-remi",
    }

    yumrepo { 'remi-test':
      descr      => 'Les RPM de remi en test pour Enterprise Linux $releasever - $basearch',
      mirrorlist => 'http://rpms.famillecollet.com/enterprise/$releasever/test/mirror',
      enabled    => 0,
      protect    => 0,
      gpgcheck   => 1,
      gpgkey     => "http://rpms.famillecollet.com/RPM-GPG-KEY-remi",
    }
  }
}