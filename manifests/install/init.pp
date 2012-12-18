# Install Zenoss Core 4.2.x
# In a lot of cases you might want to do your own tweaking and add or omit certain packages.
# This installer should get a system up and running though.

class zenoss::install {
		case $::osfamily {
      # Only supports RHEL6 for the moment
			RedHat: {
				include zenoss::install::redhat	
			}
		}
	}
}