---
layout: post
title: RabbitMQ High Availability Cluster
tags: [debian, rabbitmq, cluster, high availability, ha, mirror]
author: kuteninja
---

We needed to deploy a mirrored high availability cluster for RabbitMQ on our Amazon AWS cloud. Here you'll find notes explaining how we made this possible and some tips to get you started with it as well.


### High Availability Clusters

RabbitMQ has two clustering modes available. The first one is via the [Federation plugin](https://www.rabbitmq.com/federation.html) or creating a [High Availability](https://www.rabbitmq.com/ha.html) cluster. We'll only be discussing the last one.

We've chosen to do a High Availability Cluster since we need that, when one of the nodes go down, the other can take over with minimal or no downtime. Also, since we'll be using ELB to perform a Load Balance between both queues, we can't be sure on which node you'll end up nor it's perssistance

The main idea of using Vagrant is that it's fairly simple to create and share "boxes", which basically are small virtual machines based on VirtualBox or VMWare. 

You'll be able to have your own small testing server where you can deploy your scripts, your webpage, applets or anything you want to test before actually sending it to the production servers; and thus you'll know if the next build will fail before even attempting to do it. Just a simple typo can have your website down only because you haven't tested the build before commiting it.

You'll only need a computer with any OS you want (most OS are officially supported by both VirtualBox and Vagrant), and a pendrive or network storage for saving your boxes (at least 4GB should be free on those).


### Basic OS box

In this case we'll use VirtualBox to make our boxes. If you haven't installed it yet, try using your package manager (yum / apt) or manually download and install them from these webpages:

* VirtualBox: https://www.virtualbox.org/wiki/Downloads
* Vagrant: http://www.vagrantup.com/downloads.html

You'll need to get (in this case) Debian running, so that you can use it as a base for all your own systems. You may do so by downloading a pre-made box from this website: http://www.vagrantbox.es/

Or, if you want to, you may build it yourself using the Debian NetInstall ISO. Although, for all Linux / Mac OS users, there's a simple way to automate this using a bash script made by @dotzero that you can find here: https://github.com/dotzero/vagrant-debian-wheezy-64

Once you have a basic .box file, save it somewhere (maybe a pendrive or a remote hard disk), since it will be the base for all your next proyects. If you created your basic OS box using VirtualBox please check the label "Packing your custom box" at the end of the script to make your first .box before proceeding with the setup.


### Your first Vagrant machine

Now, let's create a new Vagrant machine using the previous Debian box file that we created or downloaded on the previous step. Let's say it's called "debian-wheezy.box":

```
# 1.- We import the box file to our system...
vagrant add box debian-wheezy ./debian-wheezy.box
# 2.- Then create a default directory
mkdir -p ~/Vagrant/machine-01/
cd ~/Vagrant/machine-01/
# 3.- And we boot our machine
vagrant init debian-wheezy
vagrant up
vagrant ssh
```

It's possible that you need to setup the "insecure vagrant key" for password-less ssh logins or you can use your own key as well changing config.ssh.private_key_path on the Vagrantfile configuration file. If you don't want to use ssh keys; the default user, named vagrant will (should) have "vagrant" as a password by default and should be able to use sudo anywhere without a password. If you created the box manually, you may need to change those settings or setup your own ssh settings by changing config.ssh.username and (maybe) config.ssh.port or config.ssh.shell on the Vagrantfile file to match your preferred settings.

You'll now be able to install anything you need (ie. MySQL, Apache, Java, etc...) on the machine without having to install it on your own computer, and you'll also be able to re-package this box in case you need to send it to a different developer for testing or even to make a new box with all your services pre-bundled.

There's also a way to make your boxes auto-prepare themselves using puppet or chef. We're not going to cover that in this case, but you can check more about that in this website: http://docs.vagrantup.com/v2/provisioning/index.html


### Packing your custom box

Once you have the Vagrant machine installed with all your preferred packages and/or services needed (ie. a LAMP stack), you may now re-package it and create a new box that already have all those services installed so you won't need to go thru all that process again and thus be able to share the box with other people. 

First you need to know what's the name of your Vagrant. It's usually the same name as your box, with the addition of a custom name (usually "default") and a timestamp. In this case, let's say it's called debian-wheezy_default-1393269383 (you may change this behaviour using the Vagrantfile's config variable v.name), let's package it...

```
# Change the name to your actual VirtualBox setup on the parameter --base
# Also, you may change where the box is outputted with the parameter --output
vagrant package --base debian-wheezy_default-1393269383 --output ~/debian-wheezy-lamp.box
```

If you want to, it's a good idea to host this file on a storage server on your office's network and you'll only need to share the Vagrantfile with all the custom setup that you wanted. In case the instance can work on a default setup, you'll only need to repeat the "first Vagrant machine" steps but using the URL for the boxfile instead of a local reference.


### And you're done!

You now have absolutely no excuses for not testing your builds and thus having a seamless night of sleep after an unexpected deployment marathon. Also, your SysAdmin and DevOps friends will deeply thank you for testing your code.
