---
layout: post
title: Embedding X.509 signatures into ReaR rescue ISOs with isomd5sum
description: How a fork of isomd5sum lets ReaR sign its rescue ISOs with an X.509 key, embedding the signature inside the ISO and verifying it at recovery time.
tags: [ReaR, isomd5sum, ISO signing, X.509, cryptography, security, it3 consultants, Linux]
author: gratien
---

<strong>Embedding X.509 signatures into ReaR rescue ISOs with isomd5sum</strong>

ReaR already protects its rescue ISO against corruption: after building the ISO it calls `implantisomd5` to store an md5sum in the trailing sectors, and when the rescue system boots it runs `checkisomd5` to verify the medium. That is a nice safety net against a bit-flip or a bad copy, but it is not a security feature — anyone can recompute an md5sum, so an attacker who replaces the ISO can simply re-implant a matching checksum.

This post is about a fork of `isomd5sum` that closes that gap. Its `implantisomd5` can sign the md5sum with a private key and store the signature inside the same trailing skip-sectors region of the ISO. There is no detached `.sig` file to lose. At recovery time `checkisomd5 --cert` verifies that embedded signature against an X.509 certificate, and with `--ca` or `--CApath` it can also check that the certificate chains to a trusted CA. The signature support is integrated into ReaR with three small staged files, and that is what the rest of this article walks through.

#### What the integration does

The flow splits into two halves — one at build time on the host that runs `rear`, one at boot time in the rescue system:

```text
rear mkrescue / mkbackup
  └─ output stage: 840_implantisomd5.sh
       implantisomd5 --cert CERT --sign-key KEY rear-HOST.iso
                     (signature is embedded in the ISO)

Rescue system boot (from CD/ISO/virtual media)
  └─ system-setup.d/70-checkisomd5.sh
       checkisomd5 --verbose --cert CERT [--ca CA] [--CApath DIR] /dev/sr0
```

The private key never leaves the build host. Only the certificate (and optionally the CA material) is shipped into the rescue image, where it is used purely to verify.

#### Prerequisites

Build and install the fork of `isomd5sum` on the host that runs ReaR. The build steps live alongside this staging tree in `README`, `RPM-BUILD.md` and `DEB-BUILD.md`. Before going further, confirm the installed tools actually know the new options:

```bash
implantisomd5 2>&1 | grep -- --sign-key
checkisomd5   2>&1 | grep -- --cert
```

ReaR resolves the tools with `type -p`, so the patched binaries must come first in `PATH`. A stock `isomd5sum` package does not understand `--cert`, which means `implantisomd5` will fail the moment signing is enabled.

Then create a signing key and certificate. A self-signed pair is enough for a first test:

```bash
openssl req -x509 -newkey rsa:4096 -nodes -days 3650 \
    -subj "/CN=rear-iso-signing" \
    -keyout /etc/pki/tls/private/cert.key -out /etc/pki/tls/certs/cert.pem
chmod 600 /etc/pki/tls/private/cert.key
```

For production, use a certificate issued by your own CA and also provide the CA bundle (`ISO_SIGNING_CA_FILE`) or a hashed directory (`ISO_SIGNING_CA_DIR`) so the recovery check can validate the chain.

Finally, ReaR must run with `OUTPUT=ISO`. Other output methods never reach `840_implantisomd5.sh`.

#### Step-by-step integration

Everything below was checked against ReaR 2.6 (2020-06-17). Other versions may have different line numbers or stage layouts.

Back up the originals first:

```bash
cd /usr/share/rear
cp -a conf/default.conf conf/default.conf.orig
cp -a output/ISO/Linux-i386/840_implantisomd5.sh output/ISO/Linux-i386/840_implantisomd5.sh.orig
cp -a skel/default/etc/scripts/system-setup.d/70-checkisomd5.sh \
      skel/default/etc/scripts/system-setup.d/70-checkisomd5.sh.orig
```

Do not leave `*.orig` files inside the ReaR tree. ReaR sources every `*.sh` file in a stage directory, and a stray copy will confuse you — or worse, packaging tools. Move them elsewhere once you are done.

**Add the defaults to `default.conf`.** Paste the snippet after `ISO_PREFIX="rear-$HOSTNAME"` (around line 789 in ReaR 2.6). It defines four variables, all empty by default:

- `ISO_SIGNING_CERT` — the X.509 certificate (PEM). Its serial is recorded in the ISO and its public key verifies the signature.
- `ISO_SIGNING_KEY` — the matching private key (PEM), used only when the ISO is built.
- `ISO_SIGNING_CA_FILE` — optional CA bundle for chain validation (`openssl verify -CAfile` style).
- `ISO_SIGNING_CA_DIR` — optional `c_rehash` directory of CA certificates (`-CApath` style).

ReaR keeps all user-settable variables with their defaults in `default.conf`. The rescue system sources `default.conf` first, then `site.conf`, `local.conf` and `rescue.conf`, so the variables exist at recovery time and pick up the user's values. With both `ISO_SIGNING_CERT` and `ISO_SIGNING_KEY` empty, behaviour is identical to stock ReaR: the md5sum is implanted without a signature.

**Replace `840_implantisomd5.sh`.** The staged version exits quietly if `implantisomd5` is not installed (as the original does). It builds the `implant_opts` array, enabling signing only when both `ISO_SIGNING_KEY` and `ISO_SIGNING_CERT` are set and readable. If they are set but unreadable it prints an error with `LogPrintError` and implants the plain md5sum, so the ISO is still produced. It adds the certificate and the optional CA file or directory to `COPY_AS_IS`, and `checkisomd5` to `PROGS` (more on why that does not quite work below). Then it runs `implantisomd5` on the single ISO (`$ISO_PREFIX.iso`) and on every split ISO (`${ISO_PREFIX}_*.iso`).

**Replace `70-checkisomd5.sh`.** This script is sourced by `system-setup` while the rescue system boots. The staged version returns early if there is no CD-ROM drive or no readable medium, or if `checkisomd5` is not in the rescue image. It always uses `--verbose`; if `ISO_SIGNING_CERT` is set and the file exists in the rescue system it adds `--cert`, plus `--ca` and `--CApath` when those files or directories exist. It runs `checkisomd5` on `/dev/$cdrom` and reports the md5 result on one line and a separate `Signature status:` line.

**Configure the site.** In `/etc/rear/local.conf` (or `site.conf`):

```bash
OUTPUT=ISO
ISO_SIGNING_CERT="/etc/pki/tls/certs/cert.pem"
ISO_SIGNING_KEY="/etc/pki/tls/private/cert.key"
# optional chain validation at recovery time
#ISO_SIGNING_CA_FILE="/etc/pki/tls/certs/ca-bundle.pem"
#ISO_SIGNING_CA_DIR="/etc/pki/tls/certs"
```

`local.conf` is copied into the rescue image as `/etc/rear/local.conf`, so the same paths are visible at boot. Do not put the private key anywhere that causes the key itself to be copied into the image. `ISO_SIGNING_KEY` is only read on the build host, but also check that `COPY_AS_IS` / `COPY_AS_IS_EXCLUDE` do not pull in `/etc/pki/tls/private`.

#### Known problem: stage ordering of COPY_AS_IS and PROGS

This is the one real gotcha, and the original ReaR script has it too. `rear mkrescue` runs the stages in this order (`lib/mkrescue-workflow.sh`):

```text
prep -> layout/save -> rescue -> build -> pack -> output
```

The rescue initramfs is assembled in `build` (which reads `COPY_AS_IS` and `PROGS`) and compressed in `pack`. `840_implantisomd5.sh` runs in `output`, after the initramfs already exists, so any change it makes to `PROGS` and `COPY_AS_IS` has no effect on the image. The stock script's own `PROGS+=( checkisomd5 )` only works because `checkisomd5` is already included some other way — for example through `REQUIRED_PROGS`/`PROGS` in `local.conf`, or because it was pulled in as a library dependency.

The consequence: with the staged files as they are, the ISO is signed, but the certificate may be missing from the rescue system. When that happens `70-checkisomd5.sh` silently skips the signature check, because it tests `-r "$ISO_SIGNING_CERT"`. A skipped check looks like a pass, which is unacceptable for a security feature.

The clean fix is to move the image-time work into the `prep` stage. Add a new script, for example `/usr/share/rear/prep/ISO/Linux-i386/335_prepare_isomd5sum_signing.sh` (any number after `330_find_isolinux.sh` works), and move into it:

- `PROGS+=( checkisomd5 )` when `implantisomd5` exists,
- the readability checks for `ISO_SIGNING_KEY` / `ISO_SIGNING_CERT`,
- the `COPY_AS_IS+=( ... )` lines for the certificate and CA material.

Use `Error` instead of a warning if signing was requested but a file is unreadable. Leave in `840_implantisomd5.sh` only the call to `implantisomd5`, relying on a variable set by the prep script (for example `ISO_SIGNING_ENABLED=yes`) or repeating the same readability test. And in `70-checkisomd5.sh`, when `ISO_SIGNING_CERT` is set but the file is missing, print an error instead of skipping:

```bash
if [[ -n "$ISO_SIGNING_CERT" && ! -r "$ISO_SIGNING_CERT" ]] ; then
    echo "ERROR: signing certificate $ISO_SIGNING_CERT missing in rescue system"
fi
```

Until that prep script exists, work around it in `local.conf`:

```bash
PROGS+=( checkisomd5 )
COPY_AS_IS+=( "$ISO_SIGNING_CERT" )
```

#### Behaviour at recovery time

`checkisomd5` runs the md5 media check first, then the signature check, and reports the signature result on a separate line:

- ISO intact and signed by the configured certificate — md5 `PASS`, signature valid.
- ISO signed, but `--cert` does not match the signer — signature check fails.
- ISO built without signing — `Signature status: MISSING`.
- `--ca` / `--CApath` given and the certificate does not chain to it — certificate rejected.
- `--ca` / `--CApath` given without `--cert` — `Signature status: NA`.

Revocation (CRL/OCSP) is not checked. The boot-time script only prints its result; it does not stop the boot. If you need recovery to halt on a bad signature, extend the script to act on the `checkisomd5` exit status, and check `checkisomd5.c` for which exit code is used for a signature failure before you depend on it.

#### Verification

Build the ISO and look for the log line about embedding the signature:

```bash
rear -v mkrescue
```

Verify on the build host, adjusting the path to your `ISO_DIR` and `ISO_PREFIX`:

```bash
checkisomd5 --verbose --cert /etc/pki/tls/certs/cert.pem /var/lib/rear/output/rear-$(hostname -s).iso
```

Do a negative test too: verify with a different certificate, and with an ISO built without signing. Both must report a failed or missing signature.

Boot the ISO in a VM attached as CD-ROM and watch the startup messages. The longer line `**** Checking the md5sum and embedded signature of the cdrom or iso image ****` means signing is active. If you see the shorter `**** Checking the md5sum of the cdrom or iso image ****`, the certificate is not in the rescue image — revisit the stage-ordering problem above. Finally, inspect the rescue image itself:

```bash
lsinitrd /var/lib/rear/output/...   # or unpack the initramfs
ls /etc/pki/tls/certs/cert.pem
type checkisomd5
```

#### Security notes

- Keep `ISO_SIGNING_KEY` root-only (mode 600). These scripts never copy it into the rescue image.
- Without `ISO_SIGNING_CA_FILE` / `ISO_SIGNING_CA_DIR`, the check trusts whatever certificate is shipped in the image. An attacker who can modify the whole ISO can replace both the certificate and the signature, so the signature then only protects against accidental corruption unless the certificate comes from a trusted separate source — a CA chain, or a certificate you compare out of band.
- Implanting modifies the ISO in place. Sign as the last step, after anything else that writes to the ISO; later processing that rewrites the file invalidates the signature.

Rolling back is straightforward: restore the three `.orig` files (or reinstall the ReaR package, which overwrites them) and remove the `ISO_SIGNING_*` lines from `local.conf`. Previously created ISOs keep working, because a signed ISO is still a valid ISO with a valid md5sum, and stock `checkisomd5` simply ignores the signature.

### References

- [Relax-and-Recover (ReaR) — GitHub](https://github.com/rear/rear)
- [Our fork of the isomd5sum project (with cert)](https://github.com/gdha/isomd5sum)
- [Original isomd5sum project (from RedHat)](https://github.com/rhboot/isomd5sum)
- [ReaR download & release notes](https://relax-and-recover.org/download/)
- [ReaR professional support — it3 consultants](https://www.it3.be/rear-support/)
