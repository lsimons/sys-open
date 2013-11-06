About
=====
apt::repo sets up /home/reprepro to contain an apt repository. Use reprepro.

  This repo is made accessable via https://ca.example.org/repos/precise/.

  See docs at
    http://manpages.ubuntu.com/manpages/hardy/man1/reprepro.1.html
    http://blog.jonliv.es/2011/04/26/creating-your-own-signed-apt-repository-and-debian-packages/
    http://wiki.debian.org/SettingUpSignedAptRepositoryWithReprepro
    https://github.com/jtopjian/puppet-reprepro/

The main differences between our setup and what's typically documented online are

  * using *full* automation of GnuPG key management
    (the common alternative is to do some of this work by hand)
  * using SSL to access to the repo, benefiting from our PKI infrastructure
    (the common alternative is using APT over SSH; unfortunately using
    client keys/certs is not working properly)
  * using a 'devel' and a 'main' within what is otherwise the 'same' repo
    (this is a reprepro feature that uses hard links to save space)
  * using some custom tools and scripts to manage adding packages to
    devel and promoting them to main
    (the common approach for people that need things like this seems to
    be to do something pretty heavyweight, i.e. run your own instance
    of launchpad)

apt::host sets up clients to use the created apt::repo.

  This uses SSL. See docs at
  
    http://212.182.0.171/cgi-bin/dwww/usr/share/doc/apt/examples/apt-https-method-example.conf.gz

Adding a package
================
To add a new package, copy it into

  /home/reprepro/repos/ex/incoming

There's a PHP script available at

  $server_name/repos/ex/app/upload.php

to help do this without needing SSH access.

Within 5 minutes, a cron job will pick it up, sign it, import it, then delete the original.

Any errors will get syslogged.

If waiting 5 minutes is too long, run

  sudo -u reprepro  /home/reprepro/includedebs.sh

This pushes the package into 'devel'. The intent is that packages live in devel for a while (getting installed on development servers), and only when they are deemed worthy promote them into 'main'.


Promoting a package
===================
To promote a package, create a file inside

  /home/reprepro/repos/ex/promote

named $package.promote, containing the absolute path to the debian file inside the devel repo.

Within 5 minutes, a cron job will pick it up and add it to the main repo.

Any errors will get syslogged.

If waiting 5 minutes is too long, run

  sudo -u reprepro  /home/reprepro/promotedebs.sh

This pushes the package from 'devel' into 'main'. The intent is that packages are only promoted to main once they are deemed properly tested and stable.
