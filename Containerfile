#
# Base
#

FROM quay.io/almalinuxorg/almalinux-bootc:10.0 AS base

# Set default target
RUN ln -sfr /usr/lib/systemd/system/multi-user.target /usr/lib/systemd/system/default.target

# Allow auto-updates
RUN ln -sr /usr/lib/systemd/system/bootc-fetch-apply-updates.timer /usr/lib/systemd/system/timers.target.wants/
RUN ln -sr /usr/lib/systemd/system/podman-auto-update.timer /usr/lib/systemd/system/timers.target.wants/

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr
RUN ln -sr /usr/lib/systemd/system/update-linode-dns.timer /usr/lib/systemd/system/timers.target.wants/

# Install Distrobox
ADD --checksum=sha256:3ecbce9b8c5b5df941f986798ffa6ea7fdf742223d42204207974c4323d5b9fc \
    https://github.com/89luca89/distrobox/archive/refs/tags/1.8.1.2.tar.gz \
    /tmp/distrobox/source.tar.gz
RUN <<EORUN
cd /tmp/distrobox
tar -x --strip-components=1 -f source.tar.gz
./install --prefix /usr
cd /
rm -fr /tmp/distrobox
EORUN

# Clean up
RUN dnf clean all
RUN echo Brute-force cleaning /var \
    && find /var/{lib,cache,log} -type f -ls \
    && rm -rf /var/{lib,cache,log}

RUN bootc container lint


#
# Headless
#

FROM base AS headless

# Install and enable Clevis
RUN dnf install -y clevis-dracut clevis-luks clevis-systemd \
    && mkdir -p /usr/lib/bootc/kargs.d \
    && echo 'kargs = ["rd.neednet=1"]' >> /usr/lib/bootc/kargs.d/99-clevis-pin-tang.toml \
    && kver=$(cd /usr/lib/modules && echo *) \
    && dracut -vf /usr/lib/modules/$kver/initramfs.img $kver

# Clean up
RUN dnf clean all
RUN echo Brute-force cleaning /var \
    && find /var/{lib,cache,log} -type f -ls \
    && rm -rf /var/{lib,cache,log}

RUN bootc container lint


#
# cyprus
#

FROM headless AS cyprus

RUN bootc container lint


#
# dogwood
#

FROM headless AS dogwood

RUN bootc container lint
