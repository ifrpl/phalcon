# Class: phalconphp::framework
# Installs the actual phalconphp framework
class phalconphp::framework (
  $version,
  $zephir_build = false,
  $ini_file     = "phalcon.ini",
  $debug        = false,
	$workdir      = '/tmp/cphalcon'
)
{
  git::clone { 'phalcon' :
    from => 'https://github.com/phalcon/cphalcon.git',
    to => $workdir,
		branch => $version,
  }

  if $version == '2.0.0' or $version == 'dev'
	{
    if $zephir_build == true
		{
      exec { 'generate' :
        require => [
          Class['phalconphp::deps::zephir'],
					Git::Clone['phalcon'],
				],
        command   => 'zephir generate',
        cwd       => $workdir,
				path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
        onlyif    => "test -f ${workdir}/config.json",
        logoutput => $debug,
        timeout   => 0
      }
			->
      exec { 'install':
        command   => 'zephir build',
        cwd       => $workdir,
				path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
        logoutput => $debug,
        timeout   => 0
      }
    }
		else
		{
      exec { 'install':
				require   => [
					Git::Clone['phalcon'],
					Class['phalconphp::deps::sys'],
				],
        command   => "${workdir}/ext/install-test",
        cwd       => "${workdir}/ext",
				path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
        onlyif    => "test -f ${workdir}/ext/install-test",
        logoutput => $debug,
        timeout   => 0
      }
    }
  }
	else
	{
    exec { 'install':
			require   => [
				Git::Clone['phalcon'],
				Class['phalconphp::deps::sys'],
			],
      onlyif    => "test -f ${workdir}/build/install",
      command   => 'sudo ./install',
      cwd       => "${workdir}/build",
			path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
      logoutput => $debug,
      timeout   => 0
    }
  }
	exec { 'clean':
		require   => Exec['install'],
		command   => "rm ${workdir} -R -f",
		path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
		logoutput => $debug,
		timeout   => 0
	}

	php::module { 'phalcon' :
		require => Exec['clean']
	}
}
