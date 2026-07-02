---
layout: default
title: Config to HTML (cfg2html) — System Configuration Collector
description: cfg2html is an Open Source Unix/Linux shell utility that collects system configuration into a readable HTML and plain-text report — useful for disaster recovery, audits, and pre-upgrade planning.
tags: [cfg2html, open source, linux, HP-UX, AIX, SunOS, system configuration, disaster recovery, sysadmin, IT3 Consultants, GPL]
author: gratien
---

## Config to HTML (cfg2html)

[cfg2html](https://www.cfg2html.com/) is a utility to collect system configuration files and settings into an HTML file and a plain-text file. Simple to run and very useful in disaster recovery situations, compliance audits, and pre-upgrade planning. cfg2html is often called the "Swiss army knife" for sysadmins.

<iframe width="280" height="210" src="https://www.youtube.com/embed/qqBf-VS9Gmk" align="right" title="cfg2html introduction video"><p>cfg2html</p></iframe>

It collects: Linux system information, Cron and At jobs, installed hardware, installed software, filesystem and swap configuration, LVM, network settings, kernel and modules, system enhancements, and application subsystems — all written into a self-contained HTML document you can open in any browser.

cfg2html works on Linux, HP-UX, SunOS, and AIX.

A [presentation at FOSDEM 2014](https://fosdem.org/2014/schedule/event/cfg2html/) is available if you want a quick overview.

### Clone and run

```bash
git clone git@github.com:cfg2html/cfg2html.git
```

### Example output

```text
#-> cfg2html
--=[ https://www.cfg2html.com ]=---------------------------------------------
Starting          cfg2html-linux version 6.x
Path to Cfg2Html  /usr/sbin/cfg2html
HTML Output File  /var/log/cfg2html/hostname.html
Text Output File  /var/log/cfg2html/hostname.txt
Errors logged to  /var/log/cfg2html/hostname.err
Local config      /etc/cfg2html/local.conf
WARNING           USE AT YOUR OWN RISK!!! :-))
--=[ https://www.cfg2html.com ]=---------------------------------------------

Collecting:  Linux System ...
Collecting:  Cron and At ...
Collecting:  Hardware ...
Collecting:  Software ...
Collecting:  Filesystems, Dump- and Swapconfiguration ...
Collecting:  LVM ...
Collecting:  Network Settings ...
Collecting:  Kernel, Modules and Libraries ...
Collecting:  System Enhancements ...
Collecting:  Applications and Subsystems ...
```

The output HTML file gives you a full snapshot of the system at collection time — ideal for keeping before/after evidence during patching or upgrades.

### Installing on HP-UX 11i

HP-UX software depots are available at the [cfg2html download page](https://www.cfg2html.com/):

```bash
swinstall -s $PWD/cfg2html_C.06.27_20151215.depot CFG2HTML
```

### Linux packages

Linux packages are built on the [openSUSE Build Service](https://build.opensuse.org/project/show/home:gdha) for a wide range of distributions. Select your distribution and look in the `noarch` subdirectory.

### Links

- [cfg2html official website](https://www.cfg2html.com/)
- [cfg2html GitHub source](https://github.com/cfg2html/cfg2html)
- [Report a bug or request a feature](https://github.com/cfg2html/cfg2html/issues)
