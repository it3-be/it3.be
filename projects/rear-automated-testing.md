---
layout: default
title: Relax-and-Recover (ReaR) Automated Testing Project
description: The ReaR Automated Testing project automates disaster recovery test scenarios across Linux distributions and hardware architectures to validate ReaR releases before publication.
tags: [rear, relax-and-recover, automated testing, linux, disaster recovery, CI, open source, GPLv3, IT3 Consultants, bareos]
author: gratien
---

## Relax-and-Recover (ReaR) Automated Testing

<img src="{{ site.url }}/images/logo/rear_logo_100.png" width="50" height="50" alt="ReaR logo">

[Relax-and-Recover (ReaR)]({{ site.url }}/projects/rear/) is a modular bare metal disaster recovery framework written in Bash and released under GPLv3. Before each release, every supported combination of Linux distribution, hardware architecture, backup method, and boot mechanism must be validated. That is a substantial matrix:

- **Distributions:** RHEL, SLES, Debian, Ubuntu, Fedora, Arch, and more
- **Architectures:** x86_64, ppc64, ppc64le, ia64, aarch64
- **Backup methods:** tar, rsync, duplicity, Bareos, and various commercial solutions
- **Boot methods:** ISO, PXE, USB

Testing this matrix manually before every release is not feasible. Disaster recovery exercises traditionally require manual intervention at each step — making automation genuinely difficult.

### What the project does

The [ReaR Automated Testing project](https://gdha.github.io/rear-automated-testing/) automates a targeted set of end-to-end disaster recovery scenarios: boot the rescue ISO, reconstruct disk layout, restore data, verify the system boots correctly. It was originally built for customers with an active [ReaR support contract]({{ site.url }}/rear-support/) as an additional service, and is published as Open Source (GPLv3) so the whole community can benefit and contribute.

Past validated scenarios include:

- CentOS 7 with PXE booting and `BACKUP=NETFS` (tar over NFS)
- Ubuntu 14.04 with ISO booting and `BACKUP=BAREOS`
- Ubuntu 16.04 with ISO booting and `BACKUP=BAREOS`

### Current status

The project is currently on hold pending renewed funding. Open Source software is free to use, but the engineering work behind it is not free to produce. If you want your specific use case covered by automated testing, subscribe to one of the [ReaR support offerings]({{ site.url }}/rear-support/) to help fund continued development.

### Resources

- [ReaR Automated Testing documentation](https://gdha.github.io/rear-automated-testing/)
- [ReaR Automated Testing GitHub source](https://github.com/gdha/rear-automated-testing)
- [ReaR Automated Testing GitHub issues](https://github.com/gdha/rear-automated-testing/issues)
- [Presentation at FrOSCon 2017](https://media.ccc.de/v/froscon2017-1957-relax-and-recover_automated_testing) — video introduction to the project
- [ReaR official website](https://relax-and-recover.org/)
