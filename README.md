# About Tiburon


Tiburon solves the problem of programmatic (database driven) booting fleets of
machine instances, inclusive of bare metal machines, and virtual machines,
without requiring local virtual or physical machine state storage.  That is,
specific virtual or physical OS, Image, and OS options are controlled by a
centralized or distributed database and object store.  This allows you to set
boot server, machine options, and so forth entirely programmatically in a
repeatable manner.  

With Tiburon, you are able to boot any network/locally bootable image.  This
includes virtual machine images, ISOs, USB images, and so on.  You can build
immutable images using tools like Nyble, Packer, Anaconda, FAI, etc. and boot
these imagees with these tools.  The utility of this cannot be overstated, in
that you can create completely controlled point-in-time OSes for deployment,
while easily setting up canary systems, and doing roll forward/roll backs
trivially, requiring only a reboot.  Further, you can use Tiburon to test your
OS images on isolated VMs before physical tests, and more generally use it as
a way to provide a real CI/CD for OSes, VMs, and hardware.


## Theory of operation

Tiburon sits atop the pxe, dhcp/bootp, web server, and object storage
mechanisms, providing event based glue logic to tie everything together, into
a functional whole.
[fill in more details]


### Configuration

[include etc/boot.json example]

### Installing Tiburon

[write installer, then document]

### Workflow

[lifecycle of an image and boot]
