# Class: phalconphp::framework
# Installs the actual phalconphp framework
class phalconphp::framework (
  $version,
  $zephir_build = false,
  $ini_file     = "phalcon.ini") {
  exec { 'git-clone-phalcon':
    command   => "git clone -b ${version} https://github.com/phalcon/cphalcon.git",
    cwd       => '/tmp',
    require   => [Class['phalconphp::deps::sys']],
    unless    => 'test -d /tmp/cphalcon',
    logoutput => true
  } ->
  exec { 'git-pull-phalcon':
    command   => 'git pull',
    cwd       => '/tmp/cphalcon',
    onlyif    => 'test -d /tmp/cphalcon',
    require   => [Exec['git-clone-phalcon']],
    logoutput => true
  }

  file { "${php::config_dir}/${ini_file}":
    ensure  => file,
    require => [Class['php']],
    purge   => true
  }

  if $version == '2.0.0' or $version == 'dev' {
    if $zephir_build == true {
      exec { 'generate-phalcon-2.0':
        command   => 'zephir generate',
        cwd       => '/tmp/cphalcon',
        require   => [
          Class['phalconphp::deps::zephir'],
          Exec['git-pull-phalcon']],
        onlyif    => 'test -f /tmp/cphalcon/config.json',
        logoutput => true,
      }

      exec { 'install-phalcon-2.0':
        command   => 'zephir build',
        cwd       => '/tmp/cphalcon',
        require   => [Exec['generate-phalcon-2.0']],
        onlyif    => 'test -f ./config.json',
        logoutput => true,
      }
    } else {
      exec { 'install-phalcon-2.0':
        command   => "/tmp/cphalcon/ext/install-test",
        cwd       => '/tmp/cphalcon/ext',
        require   => [Exec['git-pull-phalcon']],
        onlyif    => 'test -f /tmp/cphalcon/ext/install-test',
        logoutput => true,
      }
    }

    exec { 'remove-phalcon-src-2.0':
      cwd       => '/tmp',
      command   => 'rm ./cphalcon -R -f',
      require   => [Exec['install-phalcon-2.0']],
      logoutput => true,
    }

    php::augeas { 'php-load-phalcon-2.0':
      entry    => 'phalconphp/extension',
      value    => 'phalcon.so',
      target   => "${php::config_dir}/${ini_file}",
      require  => [
        File["${php::config_dir}/${ini_file}"],
        Exec['remove-phalcon-src-2.0']],
      loglevel => 'notice'
    }
  } else {
    exec { 'install-phalcon-1.x':
      command   => 'sudo ./install',
      cwd       => '/tmp/cphalcon/build',
      onlyif    => 'test -f /tmp/cphalcon/build/install',
      require   => [Exec['git-pull-phalcon']],
      logoutput => true,
    }

    exec { 'remove-phalcon-src-1.x':
      cwd       => '/tmp',
      command   => 'rm ./cphalcon -R -f',
      require   => [
        Exec['git-pull-phalcon'],
        Exec['install-phalcon-1.x']],
      logoutput => true,
    }

    php::augeas { 'php-load-phalcon-1.x':
      entry    => 'phalconphp/extension',
      target   => "${php::config_dir}/${ini_file}",
      value    => 'phalcon.so',
      require  => [
        File["${php::config_dir}/${ini_file}"],
        Exec['remove-phalcon-src-1.x']],
      loglevel => 'notice'
    }
  }
}
