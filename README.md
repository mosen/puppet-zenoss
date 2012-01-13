Zenoss core support for puppet
------------------------------

This module aims to provide support for installation of zenoss and addition of devices through the zenoss json api.

The module should have roughly the same philosophy of design as the nagios monitoring providers i.e agent configuration is a collected resource.

Because the zenoss json api could be called from either the monitored devices or the zenoss monitoring server itself, the resource type should primarily operate from the standpoint that not transmitting the json requests over the network is preferred to having each agent act itself as a caller of the zenoss json api. The intended effect is to reduce the attack surface on the monitoring server by not forcing those ports to be widely available, and preventing a man in the middle issue with device -> monitoring server api calls.

