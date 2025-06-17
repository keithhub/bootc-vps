FROM quay.io/almalinuxorg/almalinux-bootc:10.0 AS base


# Install and enable Clevis

RUN dnf install -y clevis-dracut clevis-luks clevis-systemd \
    && mkdir -p /usr/lib/bootc/kargs.d \
    && echo 'kargs = ["rd.neednet=1"]' >> /usr/lib/bootc/kargs.d/99-clevis-pin-tang.toml \
    && kver=$(cd /usr/lib/modules && echo *) \
    && dracut -vf /usr/lib/modules/$kver/initramfs.img $kver


# Clean up

RUN dnf clean all
RUN rm -rf /var/{lib,cache,log}


# Finish up by linting

RUN bootc container lint


# cyprus

FROM base AS cyprus

RUN bootc container lint


# dogwood

FROM base AS dogwood

RUN bootc container lint
