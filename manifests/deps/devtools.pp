# Class: phalcon::deps::devtools
# Installs the phalconphp devtools
# Parameters:
# [*version*] - desired devtools version  - See https://github.com/phalcon/phalcon-devtools/branches for valid branch names
class phalconphp::deps::devtools
(
	$version = '1.3.x',
	$debug   = false
)
{
	include pear
	include phalconphp::deps::sys
	include phalconphp::framework
	
	git::clone{ 'devtools' :
		require => Class['pear'],
		from => 'https://github.com/phalcon/phalcon-devtools.git',
		to => '/usr/share/php/phalcon-devtools',
		branch => $version,
	}

	file { '/usr/bin/phalcon':
		ensure  => link,
		path    => '/usr/bin/phalcon',
		target  => "/usr/share/php/phalcon-devtools/phalcon.php",
		require => [
			Class['phalconphp::deps::sys'],
			Class['phalconphp::framework'],
			Git::Clone['devtools']
		]
	}

	exec { 'chmod+x-devtools':
		command   => 'chmod ugo+x /usr/bin/phalcon',
		path => ['/bin','/usr/bin','/sbin','/usr/sbin'],
		require   => [
			Git::Clone['devtools'],
			File['/usr/bin/phalcon']
		],
		logoutput => $debug,
		timeout   => 0
	}
}
