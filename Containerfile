#
# Base
#

FROM quay.io/almalinuxorg/almalinux-bootc:10.0 AS base

# Install common packages
RUN <<EORUN
dnf install -y dnf-plugins-core epel-release
dnf config-manager --set-enabled crb
dnf install -y distrobox
EORUN

# Install sealed credstore (which requires age)
ADD --checksum=sha256:b737607e430c0c92c3a566b82c7d7a3a051a10f5c0d8e5a82848c4572e31a8e9 \
    https://github.com/str4d/rage/releases/download/v0.11.1/rage-v0.11.1-x86_64-linux.tar.gz \
    /tmp
RUN tar -x -f /tmp/rage-*-x86_64-linux.tar.gz -C /usr/bin --strip-components=1 \
    && rm /tmp/rage-*-x86_64-linux.tar.gz
COPY sealed-credstore/usr /usr

# Install Linode DNS updater
COPY linode-dns-updater/usr /usr
RUN ln -sr /usr/lib/systemd/system/update-linode-dns.timer /usr/lib/systemd/system/timers.target.wants/

# Set default target
RUN systemctl set-default multi-user.target

# Allow auto-updates
RUN ln -sr /usr/lib/systemd/system/bootc-fetch-apply-updates.timer /usr/lib/systemd/system/timers.target.wants/
RUN ln -sr /usr/lib/systemd/system/podman-auto-update.timer /usr/lib/systemd/system/timers.target.wants/

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

# Fix rd.neednet=1 blocking custom NetworkManager connections
# https://github.com/dracutdevs/dracut/issues/1062
COPY <<EOF /etc/NetworkManager/conf.d/00-system.conf
[device]
keep-configuration=no
allowed-connections=except:origin:nm-initrd-generator
EOF

# Fix logging in with userdbd users. The sed is written with an extra
# capture because I couldn't get \& into the s///.
RUN sed -E -i -e 's/^((shadow|gshadow):\s+files)$/\1 systemd/' \
    /usr/share/authselect/*/*/nsswitch.conf \
    /etc/authselect/nsswitch.conf
COPY users/etc /etc

# Clean up
RUN dnf clean all
RUN echo Brute-force cleaning /var \
    && find /var/{lib,cache,log} -type f -ls \
    && rm -rf /var/{lib,cache,log}

RUN bootc container lint


#
# beech
#

FROM headless AS beech

COPY --chmod=600 network/beech-*.nmconnection /etc/NetworkManager/system-connections/
COPY sealed-credstore/targets/beech/. /usr/lib/credstore.sealed/

RUN bootc container lint


#
# cherry
#

FROM headless AS cherry

COPY sealed-credstore/targets/cherry/. /usr/lib/credstore.sealed/

RUN bootc container lint


#
# cyprus
#

FROM headless AS cyprus

COPY sealed-credstore/targets/cyprus/. usr/lib/credstore.sealed/

RUN bootc container lint


#
# dogwood
#

FROM headless AS dogwood

COPY sealed-credstore/targets/dogwood/. usr/lib/credstore.sealed/

RUN bootc container lint


#
# elm
#

FROM headless AS elm

COPY --chmod=600 network/elm-*.nmconnection /etc/NetworkManager/system-connections/
COPY sealed-credstore/targets/elm/. /usr/lib/credstore.sealed/

RUN bootc container lint
