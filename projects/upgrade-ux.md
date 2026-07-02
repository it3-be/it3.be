---
layout: default
title: Upgrade-UX — Unix/Linux Patching and Upgrade Framework
description: Upgrade-UX is an Open Source framework for consistent, repeatable, and auditable patching and upgrading of Unix and Linux systems — supporting HP-UX, RHEL-based Linux, Solaris, and AIX.
tags: [upgrade-ux, open source, linux, HP-UX, Solaris, AIX, patching, upgrade, korn shell, IT3 Consultants, GPL]
author: gratien
---

## Upgrade-UX

<img src="{{ site.url }}/images/upgrade-ux.png" width="51" height="48" border="0" align="left" alt="upgrade-ux logo">

Upgrade-UX (`upgrade-ux`) is an Open Source framework for patching and upgrading Unix/Linux operating systems in a consistent, repeatable, and auditable way. In regulated industries and enterprise environments, simply running `yum update` is often prohibited — procedures must be controlled, documented, and produce evidence before and after each change. Upgrade-UX provides exactly that structure.

It is written entirely in Korn Shell, which is available on all major Unix platforms (Linux, HP-UX, Solaris, AIX). Each operating system has its own isolated directory tree within the framework, so platform-specific logic never interferes with other platforms. Anyone familiar with [Relax-and-Recover (ReaR)]({{ site.url }}/projects/rear/) will recognise the internal structure — Upgrade-UX is modelled on the same modular architecture.

Currently, HP-UX and Linux (RHEL-based) workflow trees are fully populated.

### Features

- Simple to use from the command line
- **Preview mode** — dry-run an upgrade and see what would happen without making changes
- **Upgrade mode** — execute the actual patching/upgrade with full logging
- Customisable via `local.conf` configuration file
- OS-independent: each platform lives in its own directory subtree
- Easily extensible with your own pre/post scripts
- Detailed log file for every run
- Evidence files generated automatically for each preview or upgrade run
- Man page included
- User documentation included
- Supports installing patch bundles from previous years using the `YEAR` variable
- ServiceGuard cluster-aware
- Configurable bail-out conditions for critical checks
- Can trigger remote alarms, syslog events, or monitoring notifications
- Built-in basic system health check
- Paid support and consultancy available from IT3 Consultants (purchase order required)

### Links

- [Upgrade-UX GitHub source](https://github.com/gdha/upgrade-ux)
- [Upgrade-UX User Guide]({{ site.url }}/projects/upgrade-ux/upgrade-ux-user-guide.html)
- [FOSDEM 2015 lightning talk](https://video.fosdem.org/2015/lightning_talks/upgrade_ux.mp4)

Questions, ideas, or feedback? Contact the development team at [gratien.dhaese@it3.be](mailto:gratien.dhaese@it3.be).
