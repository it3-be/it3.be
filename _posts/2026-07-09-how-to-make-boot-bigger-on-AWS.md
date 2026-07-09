---
layout: post
title: How to make /boot bigger on AWS (EBS volume resize)

description: How to make /boot bigger on AWS (EBS volume resize)

tags: [rear, xfs, xfs_repair, xfsdump, xfsrestore, filesystem migration, boot partition, it3 consultants, linux]
author: gratien
---

## Problem

During patching we came across a serious issue:

```
cp: error writing '/boot/initramfs-5.14.0-687.17.1.el9_8.x86_64.img': No space left on device
dracut: dracut: creation of /boot/initramfs-5.14.0-687.17.1.el9_8.x86_64.img failed
```

and we cannot proceed with booting with the new kernel.

## Solution overview

1. Create a snapshot of the original root EBS volume (34 GB)
2. Create a new volume from the snapshot with a larger size (52 GB)
3. Attach the new volume to a helper VM
4. Dump the existing filesystems (xfsdump)
5. Repartition with a larger /boot (from 524 MB to ~1.8 GB)
6. Restore the filesystem dumps (xfsrestore)
7. Update UUIDs in fstab, grub, and kernel cmdline
8. Rebuild grub and initramfs
9. Detach and attach as the new root volume

---

## Step-by-step procedure

### 1. Inspect the original disk layout

The original /dev/sda was 34 GB in size with a small 524 MB /boot partition:

```bash
parted /dev/sdh print
```

```
Model: Amazon Elastic Block Store (nvme)
Disk /dev/nvme7n1: 34.4GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  2097kB  1049kB                     bios_grub
 2      2097kB  212MB   210MB   fat16              boot, esp
 3      212MB   736MB   524MB   xfs                bls_boot
 4      736MB   34.4GB  33.6GB  xfs
```

Partition layout:
- Part 1: BIOS grub
- Part 2: /boot/efi (EFI System Partition)
- Part 3: /boot
- Part 4: / (root)

### 2. Create new volume from snapshot (52 GB) and attach to helper VM

When creating the volume from the snapshot, choose 52 GB as the target size (or a size your prefer).
Attach the new volume to another VM. The first time we run `parted print` on it,
we need to accept the "Fix" prompt to relocate the backup GPT to the end of the disk.

```bash
parted /dev/sdh print
```

```
Model: Amazon Elastic Block Store (nvme)
Disk /dev/nvme7n1: 51.5GB
Sector size (logical/physical): 512B/4096B
Partition Table: gpt
Disk Flags:

Number  Start   End     Size    File system  Name  Flags
 1      1049kB  2097kB  1049kB                     bios_grub
 2      2097kB  212MB   210MB   fat16              boot, esp
 3      212MB   736MB   524MB   xfs                bls_boot
 4      736MB   34.4GB  33.6GB  xfs
```
As you see in the above example device /dev/sdh is the same as /dev/nvme7n1.

### 3. Dump the root filesystem

Mount the root partition and create a full XFS dump (use a traget filesystem with enough free space!):

```bash
mount /dev/sdh4 /mnt

# Install xfsdump if not already present
# yum install -y xfsdump

# Dump the root filesystem (use label "root" when prompted)
xfsdump -J /mnt -f /app/elasticsearch/root.dump
```

```
xfsdump: dump complete: 153 seconds elapsed
xfsdump: Dump Status: SUCCESS
```

```bash
# Unmount the root partition
umount /mnt
```

### 4. Dump the /boot filesystem

```bash
mount /dev/sdh3 /mnt

# Dump the /boot filesystem (use label "boot" when prompted)
xfsdump -J /mnt -f /app/elasticsearch/boot.dump
```

```
xfsdump: dump complete: 7 seconds elapsed
xfsdump: Dump Status: SUCCESS
```

```bash
# Unmount the /boot partition
umount /mnt
```

### 5. Verify the dump files are present

```bash
ls -l /app/elasticsearch/*.dump
```

```
-rw-r--r-- 1 root root   259353192 Jul  6 17:17 boot.dump
-rw-r--r-- 1 root root 10299749552 Jul  6 17:16 root.dump
```

### 6. Remove old partitions 3 and 4

```bash
# Remove the root partition (part 4)
parted /dev/nvme7n1 rm 4

# Remove the old /boot partition (part 3)
parted /dev/nvme7n1 rm 3
```

Verify only partitions 1 and 2 remain:

```bash
parted /dev/sdh print
```

```
Number  Start   End     Size    File system  Name  Flags
 1      1049kB  2097kB  1049kB                     bios_grub
 2      2097kB  212MB   210MB   fat16              boot, esp
```

### 7. Create new larger partitions

Create a new /boot partition (part 3) of ~1.8 GB and a new root partition (part 4) using the remaining space:

```bash
# New /boot: from 212MB to 2048MB (~1.8 GB, was 524 MB)
parted /dev/nvme7n1 mkpart primary xfs 212MB 2048MB

# New root: from 2048MB to end of disk
parted /dev/nvme7n1 mkpart primary xfs 2048MB 100%
```

Set the bls_boot flag on partition 3:

```bash
parted /dev/nvme7n1 set 3 bls_boot on
```

Verify the new layout:

```bash
parted /dev/sdh print
```

```
Number  Start   End     Size    File system  Name     Flags
 1      1049kB  2097kB  1049kB                        bios_grub
 2      2097kB  212MB   210MB   fat16                 boot, esp
 3      212MB   2048MB  1836MB  xfs          primary
 4      2048MB  51.5GB  49.5GB               primary
```

### 8. Format the new partitions with XFS

```bash
# Format /boot partition
mkfs.xfs -f /dev/nvme7n1p3

# Format root partition
mkfs.xfs -f /dev/nvme7n1p4
```

### 9. Restore the /boot filesystem

```bash
# Mount the new /boot partition
mount /dev/nvme7n1p3 /mnt

# Restore the boot dump
xfsrestore -f /app/elasticsearch/boot.dump /mnt
```

```
xfsrestore: Restore Status: SUCCESS
```

```bash
# Verify the contents
ls /mnt
```

```
config-5.14.0-611.41.1.el9_7.x86_64  grub2  initramfs-5.14.0-611.41.1.el9_7.x86_64.img  ...
```

```bash
# Unmount /boot
umount /mnt
```

### 10. Restore the root filesystem

```bash
# Mount the new root partition
mount /dev/nvme7n1p4 /mnt

# Restore the root dump
xfsrestore -f /app/elasticsearch/root.dump /mnt
```

### 11. Get the new UUIDs

```bash
# /boot/efi partition
blkid /dev/nvme7n1p2
```

```
/dev/nvme7n1p2: SEC_TYPE="msdos" UUID="7B77-95E7" TYPE="vfat" PARTUUID="68b2905b-df3e-4fb3-80fa-49d1e773aa33"
```

```bash
# /boot partition (NEW UUID)
blkid /dev/nvme7n1p3
```

```
/dev/nvme7n1p3: UUID="e6293e08-8b66-4033-ab32-70a9ed21aef9" TYPE="xfs" PARTLABEL="primary" PARTUUID="75590e8e-0b8d-46f8-b98f-fd8c9859f545"
```

```bash
# / root partition (NEW UUID)
blkid /dev/nvme7n1p4
```

```
/dev/nvme7n1p4: UUID="b8b7a302-1f3f-4587-a73a-d115c5f97dc6" TYPE="xfs" PARTLABEL="primary" PARTUUID="75566c5e-ada4-4ad4-b158-8fc36def004b"
```

### 12. Update configuration files with new UUIDs

Mount the full filesystem hierarchy:

```bash
mount /dev/sdh4 /mnt
mount /dev/sdh3 /mnt/boot
mount /dev/sdh2 /mnt/boot/efi
```

Edit the following files, replacing old UUIDs with the new ones from step 11:

```bash
# Update /etc/fstab with the new UUIDs for / and /boot
vi /mnt/etc/fstab

# Update the kernel command line with the new root UUID
vi /etc/kernel/cmdline

# Update the GRUB EFI configuration with the new /boot UUID
vi /mnt/boot/efi/EFI/redhat/grub.cfg

# Update the main GRUB configuration
vi /mnt/boot/grub2/grub.cfg
```

Verify all root=UUID references are updated:

```bash
grep -r 'root=UUID' /mnt/boot/grub2/grub.cfg /boot/loader/entries/*.conf
```

The configuration files under the `/boot/loader/entries` directory must be edit as well!

### 13. Chroot and rebuild bootloader and initramfs

Bind-mount the virtual filesystems and chroot:

```bash
mount -t proc none /mnt/proc
mount -t sysfs sys /mnt/sys
mount -o bind /dev /mnt/dev

chroot /mnt
```

Inside the chroot, rebuild GRUB and the initramfs:

```bash
# Regenerate GRUB configuration
grub2-mkconfig -o /boot/grub2/grub.cfg

# Update the kernel boot parameters with the new root UUID
grubby --update-kernel=ALL --args="root=UUID=b8b7a302-1f3f-4587-a73a-d115c5f97dc6"

# Verify the UUID is now in grub.cfg
grep dc6 /boot/grub2/grub.cfg

# Rebuild the initramfs to pick up the new UUID
dracut -f /boot/initramfs-$(uname -r).img $(uname -r)

# Verify the initramfs contains the correct root UUID
lsinitrd /boot/initramfs-$(uname -r).img | grep cmdline

# Exit the chroot
exit
```

### 14. Clean up and unmount

```bash
umount /mnt/boot/efi
umount /mnt/boot
umount /mnt/dev
umount /mnt/sys
umount /mnt/proc
umount /mnt
```

### 15. Attach the volume as root disk and boot

Detach the volume from the helper VM and attach it as the root volume (`/dev/sda` or `/dev/xvda`) on the target instance. Boot the instance.

---

## Troubleshooting

If the instance drops into dracut emergency shell with an error like:

```
Warning: /dev/disk/by-uuid/3cbab692-fa3c-41b0-84b3-4ab4a560d6d2 does not exist
```

This means the old UUID is still referenced somewhere. Attach the volume to a helper VM again and verify:

```bash
# Check the actual UUIDs on the partitions
blkid /dev/sdh3
blkid /dev/sdh4
```

Then repeat steps 12-14 ensuring **all** references to the old UUIDs are replaced with the new ones in:
- `/etc/fstab`
- `/etc/kernel/cmdline`
- `/boot/grub2/grub.cfg`
- `/boot/loader/entries/*.conf`
- `/boot/efi/EFI/redhat/grub.cfg`
