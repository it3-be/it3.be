---
layout: default
title: Relax-and-Recover (ReaR) — Open Source Linux Disaster Recovery
description: ReaR is the de facto standard bare metal disaster recovery framework on Linux, written in Bash, released under GPLv3, and actively maintained by IT3 Consultants since 2006.
tags: [rear, relax-and-recover, linux disaster recovery, bare metal recovery, open source, bash, GPLv3, IT3 Consultants, ReaR support]
author: gratien
---

## Relax-and-Recover (ReaR)

<img src="{{ site.url }}/images/logo/rear_logo_100.png" width="50" height="50" alt="ReaR logo">

[Relax-and-Recover (ReaR)](https://relax-and-recover.org/) is an Open Source bare metal disaster recovery framework started in 2006. It is the successor to the [Make CD-ROM Recovery (mkCDrec)]({{ site.url }}/projects/mkcdrec/) project and has become the de facto standard Linux disaster recovery tool — shipped natively with Fedora, RHEL, openSUSE, SUSE Linux Enterprise, Ubuntu, and Debian.

### What ReaR does

ReaR is a modular disaster recovery engine written entirely in Bash and released under GPLv3. It works in two complementary steps:

1. **Rescue image creation** — ReaR snapshots your running system's disk layout, bootloader, network configuration, and hardware details into a bootable ISO image. This can be done online, without taking the system down.
2. **Recovery** — Boot the ISO on bare metal (or a VM), and ReaR reconstructs partitions, LVM volumes, filesystems, and the bootloader, then restores data from the backup.

Backups can be stored almost anywhere: NFS, CIFS/SMB, USB, SAN, S3-compatible object storage, or PXE. ReaR integrates with commercial backup solutions (IBM Spectrum Protect, Veritas NetBackup, Micro Focus Data Protector) as well as Open Source tools (Bareos, Bacula, Borg, duplicity, rsync).

### Current status

ReaR v2.9 was released in January 2025. It is actively maintained at [github.com/rear/rear](https://github.com/rear/rear).

### Getting support

If you need help setting up ReaR, adding new features, or need guaranteed support for your environment, IT3 Consultants offers [paid ReaR support services]({{ site.url }}/rear-support/) including support contracts, workshops, and custom integration work.

### Resources

- [ReaR official website](https://relax-and-recover.org/)
- [ReaR User Guide Documentation](https://relax-and-recover.org/rear-user-guide/)
- [ReaR GitHub source](https://github.com/rear/rear)
- [ReaR User Guide GitHub source](https://github.com/rear/rear-user-guide)
- [ReaR User Guide GitHub issues](https://github.com/rear/rear-user-guide/issues)
- [ReaR User Guide Sponsors](https://github.com/rear/rear-user-guide/blob/master/SPONSORS.md)
