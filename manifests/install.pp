# Install Zenoss Core 4.2.x
# In a lot of cases you might want to do your own tweaking and add or omit certain packages.
# This installer provides you with an easy way to get a basic zenoss core installation running.

class zenoss::install {
  case $::osfamily {
    # Only supports RHEL6 for the moment, because that is my testing platform.
    RedHat: {
      include zenoss::install::redhat
    }
  }
}