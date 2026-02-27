---
layout: post
title: mount /var/lib/grub/esp unknown filesystem type 'linux_raid_member'

description: How installing chrony package failed with unknown filesystem type 'linux_raid_member'

tags: [ubuntu 22, it3 consultants, Linux]
author: gratien
---

<strong>How installing chrony package failed with unknown filesystem type 'linux_raid_member'</strong>

While trying to install the chrony package:

```
# apt-get install chrony
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
chrony is already the newest version (4.2-2ubuntu2).
0 upgraded, 0 newly installed, 0 to remove and 108 not upgraded.
1 not fully installed or removed.
After this operation, 0 B of additional disk space will be used.
Do you want to continue? [Y/n] 
Setting up grub-efi-amd64-signed (1.187.12+2.06-2ubuntu14.8) ...
mount: /var/lib/grub/esp: unknown filesystem type 'linux_raid_member'.
dpkg: error processing package grub-efi-amd64-signed (--configure):
 installed grub-efi-amd64-signed package post-installation script subprocess returned error exit status 32
Errors were encountered while processing:
 grub-efi-amd64-signed
needrestart is being skipped since dpkg has failed
E: Sub-process /usr/bin/dpkg returned an error code (1)
```

After searching on the internet came across a posting [1] where the following actions fixed the  issue:

```
# cd /var/lib/dpkg/info
# tar cvf /tmp/var_lib_dpkg_info_grub.tar grub*
# rm grub*
# dpkg --configure -a
Setting up grub-efi-amd64-signed (1.187.12+2.06-2ubuntu14.8) ...
```

After doing that, everything runs smooth again.




### References

[1] [grub-efi-amd64-signed dependency issue in Ubuntu 22.04](https://askubuntu.com/questions/1431786/grub-efi-amd64-signed-dependency-issue-in-ubuntu-22-04lts)
