# Install Zenoss core stack or from source

class zenoss::install (
	$install_source_only = false # Only install from source, even if packages are available.
) {
	if $install_source_only {
		include zenoss::install::source
	} else {
		case $::operatingsystem {
			debian: { # Entire stack from zenoss-dev repository
				include zenoss::install::debian
			}
			default: { # Build from source
				include zenoss::install::source
			}
		}
	}
}