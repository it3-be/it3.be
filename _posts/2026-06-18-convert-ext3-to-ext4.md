---
layout: post
title: Converting EXT3 file systems to EXT4 with the help of ReaR

description: Learn how to safely convert all EXT3 file systems to EXT4 on a running Linux server using ReaR mountonly and the convert-ext3-to-ext4 tool — without a full reinstall.

tags: [rear, ext3, ext4, tune2fs, e2fsck, lvm, filesystem migration, disaster recovery, it3 consultants, linux]
author: gratien
---

Many enterprise Linux servers — especially those installed years ago on RHEL/CentOS — still run ext3 file systems. Migrating to ext4 in-place, without a reinstall, is possible but requires care: the root and boot partitions cannot be unmounted while the system is live. This post shows how to do it safely using [Relax-and-Recover (ReaR)](https://relax-and-recover.org) and the companion [convert-ext3-to-ext4](https://github.com/gdha/convert-ext3-to-ext4) tool.

> **Warning:** The `tune2fs` conversion enables ext4 feature flags and updates the superblock, but existing data blocks are **not** rewritten to use extents. Full extent-based benefits (reduced fragmentation, better large-file performance) apply only to newly written data after conversion. For workloads where that matters, a backup-and-reformat approach gives better results. Always take a backup before proceeding.

### Why upgrade from ext3 to ext4?

* **Performance**
  * Larger maximum file and filesystem sizes (ext4 supports up to 1 exabyte volumes vs ext3's 32 TB)
  * Faster `fsck` since ext4 skips unallocated blocks
  * Delayed allocation and multiblock allocation reduce fragmentation and improve write throughput

* **Reliability**
  * Extents replace the old block mapping scheme, reducing metadata overhead and fragmentation for large files
  * Journal checksumming reduces the chance of corruption during crashes
  * Better handling of large directories (HTree indexing)

* **Features**
  * Timestamps with nanosecond precision (ext3 only had 1-second resolution)
  * Persistent pre-allocation (`fallocate`), useful for databases and media applications
  * Backward compatibility: ext4 can mount ext3 filesystems, easing migration

### Prerequisites

Two tools must be available on the target system:

- **[Relax-and-Recover (ReaR)](https://relax-and-recover.org/download/)** — v2.9 or later recommended (current stable release as of January 2025)
- **[convert-ext3-to-ext4](https://github.com/gdha/convert-ext3-to-ext4)** — installed to `/usr/sbin/` on the target system

A ReaR rescue ISO must already exist. If you haven't created one yet, run:

```bash
rear mkrescue
```

This creates a bootable ISO that includes the system's disk layout. No full data backup is required for this procedure — only the rescue image.

### Step 1 — Boot into the ReaR rescue environment

Attach the ReaR rescue ISO to the target system (virtual media, USB, or physical disc) and boot from it. You will land at the ReaR rescue shell prompt.

Check whether `convert-ext3-to-ext4` was included in the rescue image:

```bash
ls /usr/sbin/convert-ext3-to-ext4
```

If it is missing, don't worry — you will copy it from the mounted filesystem in Step 3.

### Step 2 — Mount the target filesystems with `rear mountonly`

`rear mountonly` reassembles the disk layout (LVM, partitions, etc.) and mounts the filesystems under `/mnt/local` — without restoring any data. This gives you a safe, offline view of the system to work on.

```bash
# rear -v mountonly
Relax-and-Recover 2.6 / 2020-06-17
Running rear mountonly (PID 714)
Using log file: /var/log/rear/rear-ITSGBHHLSP00479.log
Running workflow mountonly within the ReaR rescue/recovery system
Comparing disks
Ambiguous disk layout needs manual configuration (more than one disk with same size
used in '/var/lib/rear/layout/disklayout.conf')
Switching to manual disk layout configuration
Using /dev/sda (same name and same size 48318382080) for recreating /dev/sda
Using /dev/sdb (same name and same size 34359738368) for recreating /dev/sdb
Using /dev/sdc (same name and same size 107374182400) for recreating /dev/sdc
Using /dev/sdd (same name and same size 21474836480) for recreating /dev/sdd
Using /dev/sde (same name and same size 21474836480) for recreating /dev/sde
Current disk mapping table (source => target):
/dev/sda => /dev/sda
/dev/sdb => /dev/sdb
/dev/sdc => /dev/sdc
/dev/sdd => /dev/sdd
/dev/sde => /dev/sde
Confirm or edit the disk mapping
1) Confirm disk mapping and continue 'rear mountonly'
2) Confirm identical disk mapping and proceed without manual configuration
3) Edit disk mapping (/var/lib/rear/layout/disk_mappings)
4) Use Relax-and-Recover shell and return back to here
5) Abort 'rear mountonly'
(default '1' timeout 300 seconds)
1
User confirmed disk mapping
Confirm or edit the disk layout file
1) Confirm disk layout and continue 'rear mountonly'
2) Edit disk layout (/var/lib/rear/layout/disklayout.conf)
3) View disk layout (/var/lib/rear/layout/disklayout.conf)
4) View original disk space usage (/var/lib/rear/layout/config/df.txt)
5) Use Relax-and-Recover shell and return back to here
6) Abort 'rear mountonly'
(default '1' timeout 300 seconds)
1
User confirmed disk layout file
Confirm or edit the disk recreation script
1) Confirm disk recreation script and continue 'rear mountonly'
2) Edit disk recreation script (/var/lib/rear/layout/diskrestore.sh)
3) View disk recreation script (/var/lib/rear/layout/diskrestore.sh)
4) View original disk space usage (/var/lib/rear/layout/config/df.txt)
5) Use Relax-and-Recover shell and return back to here
6) Abort 'rear mountonly'
(default '1' timeout 300 seconds)
1
User confirmed disk recreation script
Start target system mount.
Mounting filesystem /
Mounting filesystem /home
Mounting filesystem /opt
Mounting filesystem /opt/Tanium
Mounting filesystem /tmp
Mounting filesystem /var
Mounting filesystem /var/log
Mounting filesystem /var/log/audit
Mounting filesystem /usr/sap
Mounting filesystem /sapmnt/A31
Mounting filesystem /oracle/client
Mounting filesystem /boot
Disk layout processed.
Confirm the recreated disk layout or go back one step
1) Confirm recreated disk layout and continue 'rear mountonly'
2) Go back one step to redo disk layout recreation
3) Use Relax-and-Recover shell and return back to here
4) Abort 'rear mountonly'
(default '1' timeout 300 seconds)
1
User confirmed recreated disk layout
Running POST_RECOVERY_SCRIPT
'/mnt/local/u02/restore_oracle_u02_database_directory.sh'
Finished 'mountonly'. The target system is mounted at '/mnt/local'.
Exiting rear mountonly (PID 714) and its descendant processes ...
Running exit tasks
```

Verify all expected filesystems are visible under `/mnt/local` before continuing:

```bash
df -hT | grep /mnt/local
```

You should see every partition listed with its mount point prefixed by `/mnt/local/`. If anything is missing, investigate before proceeding.

### Step 3 — Make `convert-ext3-to-ext4` available

If the tool was not bundled in the rescue image, copy it from the now-mounted system:

```bash
cp /mnt/local/usr/sbin/convert-ext3-to-ext4 /tmp
chmod +x /tmp/convert-ext3-to-ext4
```

### Step 4 — Run the conversion

```text
# /tmp/convert-ext3-to-ext4

***********************************************************************************
* Program: convert-ext3-to-ext4
* Purpose: With the help of 'rear mountonly' (after booting via the ReaR ISO image)
* -------  we will convert all available EXT3 file systems to EXT4 type, incl.
*          the boot device.
* Written by Gratien D'haese
* Version: 2.0 (C rewrite)
***********************************************************************************

Did you already run 'rear -v mountonly'?
Press any key to continue, or Control-C to exit.
Found 12 ext3 filesystem(s) and 0 ext4 filesystem(s)
------------------------------------------------------
Converting boot device /dev/sda1 on file system /mnt/local/boot
* Convert EXT3 to EXT4 on device /dev/sda1
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/sda1
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/sda1: ***** FILE SYSTEM WAS MODIFIED *****
/dev/sda1: 370/32768 files (13.0% non-contiguous), 61504/131072 blocks
Perform unmount of all filesystems under /mnt/local
------------------------------------------------------
...
*** Remounting all file systems with EXT4
*** Proof that file systems are now mounted as EXT4
/dev/mapper/vg00-lv_root on /mnt/local type ext4 (rw,relatime)
/dev/sda1 on /mnt/local/boot type ext4 (rw,relatime)
/dev/mapper/vg02-lvoraclnt on /mnt/local/oracle/client type ext4 (rw,relatime)
/dev/mapper/vg01-lvusrsapmnt on /mnt/local/sapmnt/A31 type ext4 (rw,relatime)
/dev/mapper/vg01-lvusrsap on /mnt/local/usr/sap type ext4 (rw,relatime)
/dev/mapper/vg00-lv_log on /mnt/local/var/log type ext4 (rw,relatime)
/dev/mapper/vg00-lv_var on /mnt/local/var type ext4 (rw,relatime)
/dev/mapper/vg00-lv_tmp on /mnt/local/tmp type ext4 (rw,relatime)
/dev/mapper/vg00-lv_opt on /mnt/local/opt type ext4 (rw,relatime)
/dev/mapper/vg00-lv_home on /mnt/local/home type ext4 (rw,relatime)
/dev/mapper/vg00-lv_tanium on /mnt/local/opt/Tanium type ext4 (rw,relatime)
/dev/mapper/vg00-lv_audit on /mnt/local/var/log/audit type ext4 (rw,relatime)
--------------------------------------------------------------
Do not forget to double check /mnt/local/etc/fstab!
File system(s) still defined as ext3 in /mnt/local/etc/fstab:
Temporary helper file: /tmp/mountme
Done.
```

The tool runs `tune2fs -O extents,uninit_bg,dir_index,has_journal` on each device to enable ext4 features, then `e2fsck` to verify consistency, and finally updates `/etc/fstab` entries from `ext3` to `ext4`. At the end it remounts everything and confirms the new filesystem type.

> **Note:** The line `File system(s) still defined as ext3 in /mnt/local/etc/fstab:` followed by nothing means the tool found no remaining ext3 entries — the fstab update was successful. If any are listed there, manually edit `/mnt/local/etc/fstab` before rebooting.

### Step 5 — Verify fstab and reboot

Double-check the fstab has no remaining `ext3` entries:

```bash
grep ext3 /mnt/local/etc/fstab
```

No output means you are clean. Then eject the rescue media and reboot:

```bash
eject /dev/cdrom
reboot
```

After the system comes back up, confirm the live filesystems:

```bash
df -hT | grep ext
```

All partitions should now show `ext4` in the type column.

### References

- [Relax-and-Recover (ReaR) — GitHub](https://github.com/rear/rear)
- [ReaR Download & Release Notes (v2.9, January 2025)](https://relax-and-recover.org/download/)
- [convert-ext3-to-ext4 — GitHub](https://github.com/gdha/convert-ext3-to-ext4)
- [ext3 to ext4 conversion — unix.stackexchange.com](https://unix.stackexchange.com/questions/126708/converting-a-filesystem-from-ext3-to-ext4)
- [EXT4 vs EXT3 — dev.to](https://dev.to/adityabhuyan/the-advantages-and-disadvantages-of-ext4-vs-ext3-in-linux-systems-4pcp)
