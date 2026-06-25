---
layout: post
title: Converting EXT3 file systems to EXT4 with the help of ReaR

description: Converting EXT3 file systems to EXT4 with the help of ReaR

tags: [rear, ext3, ext4, it3 consultants, Linux]
author: gratien
---

<strong>Converting EXT3 file systems to EXT4 with the help of ReaR</strong>

### Ext4 offers several meaningful improvements over ext3

* Performance
  * Larger maximum file and filesystem sizes (ext4 supports up to 1 exabyte volumes vs ext3's 32TB)
  * Faster fsck (filesystem check) since ext4 doesn't check unallocated blocks
  * Delayed allocation and multiblock allocation reduce fragmentation and improve write throughput

* Reliability
  * Extents replace the old block mapping scheme, reducing metadata overhead and fragmentation for large files
  * Journal checksumming reduces the chance of corruption during crashes
  * Better handling of large directories (HTree indexing)

* Features
  * Timestamps with nanosecond precision (ext3 only had 1-second resolution)
  * Persistent pre-allocation (fallocate), useful for databases and media applications
  * Backward compatibility: ext4 can mount ext3 filesystems, easing migration

### How to perform the actual convertion to ext4

We need two programs to be installed on the target system to speed this up:

- Relax-and-Recover (ReaR)
- convert-ext3-to-ext4

First of all, a ReaR rescue image must be present. If not configure ReaR to make a rescue image, therefore, check the ReaR web pages. A minimum is `rear mkrescue` to go to the next step.

You need to attach the ReaR rescue imagei on the target system (and we do not need the backup of the operating system) and boot from the ISO image into the ReaR rescue shell.

Once you have the rescue prompt you can check if the `convert-ext3-to-ext4` program is available in the ReaR rescue image. If this is not the case, do not worry we can still copy if from the mounted filesystem (see next step).

Then, run `rear -v mountonly`:

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

So far so good, check with `df` all file systems are present (with prefix `/mnt/local/`).

When the `convert-ext3-to-ext4` program was not available in the ReaR image you better copied it from the mount file systems to `/tmp`:

```bash
cp /mnt/local/usr/sbin/convert-ext3-to-ext4  /tmp
```

Now, you can run the `/tmp/convert-ext3-to-ext4` program to perform its task it was designed for:

```bash
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
*** Converting device /dev/mapper/vg02-lvoraclnt on file system
/mnt/local/oracle/client
* Convert EXT3 to EXT4 on device /dev/mapper/vg02-lvoraclnt
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg02-lvoraclnt
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg02-lvoraclnt: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg02-lvoraclnt: 11/1310720 files (0.0% non-contiguous), 126322/5242624
blocks
* Change FStype to ext4 of File System /oracle/client in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg01-lvusrsapmnt on file system
/mnt/local/sapmnt/A31
* Convert EXT3 to EXT4 on device /dev/mapper/vg01-lvusrsapmnt
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg01-lvusrsapmnt
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg01-lvusrsapmnt: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg01-lvusrsapmnt: 1052/5242880 files (65.7% non-contiguous),
1230053/5242880 blocks
* Change FStype to ext4 of File System /sapmnt/A31 in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg01-lvusrsap on file system /mnt/local/usr/sap
* Convert EXT3 to EXT4 on device /dev/mapper/vg01-lvusrsap
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg01-lvusrsap
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg01-lvusrsap: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg01-lvusrsap: 4661/7864320 files (18.5% non-contiguous),
1552932/7864320 blocks
* Change FStype to ext4 of File System /usr/sap in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_audit on file system
/mnt/local/var/log/audit
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_audit
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_audit
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_audit: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_audit: 16/262144 files (37.5% non-contiguous), 57560/1048576
blocks
* Change FStype to ext4 of File System /var/log/audit in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_log on file system /mnt/local/var/log
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_log
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_log
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_log: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_log: 772/262144 files (59.1% non-contiguous), 319868/1048576
blocks
* Change FStype to ext4 of File System /var/log in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_var on file system /mnt/local/var
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_var
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_var
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_var: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_var: 17418/786432 files (9.1% non-contiguous), 1076561/3145728
blocks
* Change FStype to ext4 of File System /var in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_tmp on file system /mnt/local/tmp
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_tmp
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_tmp
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
/lost+found not found. Create? yes
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_tmp: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_tmp: 157/458752 files (4.5% non-contiguous), 46564/1835008
blocks
* Change FStype to ext4 of File System /tmp in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_tanium on file system
/mnt/local/opt/Tanium
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_tanium
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_tanium
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
/lost+found not found. Create? yes
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_tanium: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_tanium: 15857/196608 files (15.7% non-contiguous),
428180/786432 blocks
* Change FStype to ext4 of File System /opt/Tanium in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_opt on file system /mnt/local/opt
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_opt
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_opt
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_opt: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_opt: 49247/327680 files (5.4% non-contiguous), 610335/1310720
blocks
* Change FStype to ext4 of File System /opt in /mnt/local/etc/fstab
------------------------------------------------------
*** Converting device /dev/mapper/vg00-lv_home on file system /mnt/local/home
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_home
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_home
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_home: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_home: 1592/262144 files (2.5% non-contiguous), 54356/1048576
blocks
* Change FStype to ext4 of File System /home in /mnt/local/etc/fstab
------------------------------------------------------
*** Dealing with /mnt/local (root filesystem)
* Converting /mnt/local now
* Convert EXT3 to EXT4 on device /dev/mapper/vg00-lv_root
tune2fs 1.45.6 (20-Mar-2020)
* Perform a file system check on /dev/mapper/vg00-lv_root
e2fsck 1.45.6 (20-Mar-2020)
Pass 1: Checking inodes, blocks, and sizes
Pass 2: Checking directory structure
Pass 3: Checking directory connectivity
Pass 3A: Optimizing directories
Pass 4: Checking reference counts
Pass 5: Checking group summary information
/dev/mapper/vg00-lv_root: ***** FILE SYSTEM WAS MODIFIED *****
/dev/mapper/vg00-lv_root: 198626/524288 files (5.6% non-contiguous),
1541871/2097152 blocks
* Change FStype to ext4 of File System / in /mnt/local/etc/fstab
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
/dev/mapper/vg00-lv_log on /mnt/local/var/log type ext4 (rw,relatime)
/dev/mapper/vg00-lv_tanium on /mnt/local/opt/Tanium type ext4 (rw,relatime)
/dev/mapper/vg00-lv_audit on /mnt/local/var/log/audit type ext4 (rw,relatime)
--------------------------------------------------------------
Do not forget to double check /mnt/local/etc/fstab!
File system(s) still defined as ext3 in /mnt/local/etc/fstab:
Temporary helper file: /tmp/mountme
Done.
```

And, now you can reboot into the real target system (perhaps you need to run `eject /dev/crom` before you can umount the ISO image).

As a  result all previous EXT3 file systems are now of type EXT4 with a slighter better performance and realibilty.

Have fun.

### References

- [Relax-and-Recover (ReaR)](https://github.com/rear/rear)

- [convert-ext3-to-ext4](https://github.com/gdha/convert-ext3-to-ext4)
