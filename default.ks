# Installation method
cmdline

# Image
ostreecontainer --url %%GHCR_IMAGE_PATH%%

# Language and keyboard settings
lang en_US.UTF-8
keyboard us

# System timezone
timezone America/New_York --utc

# kdump
%addon com_redhat_kdump --disable
%end

# Wipe disk
zerombr
clearpart --all --initlabel

# Disk partitioning
part biosboot --fstype=biosboot --size=1
part /boot --fstype=xfs --size=1536
part pv.1 --fstype=lvmpv --size=1 --grow --encrypted --luks-version=luks2

volgroup main pv.1
logvol swap --fstype=swap --size=8192 --name=swap --vgname=main
logvol none --size=1 --grow --thinpool --name=pool00 --vgname=main
logvol / --fstype=xfs --size=51200 --thin --poolname=pool00 --name=root --vgname=main
logvol /home --fstype=xfs --size=10240 --thin --poolname=pool00 --name=home --vgname=main

# Root
rootpw --lock

# User
user --name keith --groups=wheel --iscrypted --password="$6$SqQklh3y2BEql6ZV$al0zgxuRU3RTJoLFqrHBkCLKN7vnoKEM.sQ2gs4Del1IFY8s2A0ZvlMmOZvP8NH0Stjx.MTEodHkMalLflYU1."
sshkey --username keith "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXUzN2aSID7Zd5lARAw+mC4eORXOWjueVkhTNjd9R/J khubbard@kh8"

# Reboot
reboot
