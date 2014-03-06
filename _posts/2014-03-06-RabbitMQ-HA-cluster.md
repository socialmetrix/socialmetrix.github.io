---
layout: post
title: RabbitMQ High Availability Cluster
tags: [debian, rabbitmq, cluster, high availability, ha, mirror]
author: kuteninja
---

We needed to deploy a mirrored high availability cluster for RabbitMQ on our Amazon AWS cloud. Here you'll find notes explaining how we made this possible and some tips to get you started with it as well.


### High Availability Clusters

RabbitMQ has two clustering modes available. The first one is via the [Federation plugin](https://www.rabbitmq.com/federation.html) or creating a [High Availability](https://www.rabbitmq.com/ha.html) cluster. We'll only be discussing the last one.

We've chosen to do a High Availability Cluster because, in case one of the nodes went offline, the other one must take over with minimal or no downtime. Also, since we'll be using Amazon ELB for load balancing both queue servers, we can't be sure on which node you'll end up nor it's persistence across future requests, hence both nodes should have the same information at all times. 

Since all the data and push / pull requests will be replicated and processed by both nodes (assuming they're both online), the machines must have a relatively powerful CPU, and the best network connection possible between them. We haven't had issues working with two m3.large instances on different availability zones, although you should make as much performance, stress and worst case scenario tests as you can to be sure that everything will work out.

Let's begin our crusade for a redundant, cloud friendly, RabbitMQ HA cluster!


### Queue Server Setup

In this case we'll deploy the cluster on Debian 7 ("Wheezy") based AMIs, if you're using Red Hat or another linux distro, the steps might differ but the logic will be basically the same.

```bash
# RabbitMQ setup (.deb based to avoid unwanted updates)
wget https://www.rabbitmq.com/releases/rabbitmq-server/v3.2.3/rabbitmq-server_3.2.3-1_all.deb
dpkg -i rabbitmq-server_3.2.3-1_all.deb
# You may need to install or update erlang before installing rabbitmq-server
```

Now, you must setup which ports you'll open to allow the servers to talk to each other, in this case we opened ports 47000-47500. You must also open TCP ports 4369, 5672 between them, for erlang and rabbitmq services; and if you're planning to use the web-management interface you should to open TCP ports 15672 and 55672. We'll also set a custom cookie parameter, which must be the same across all RabbitMQ nodes.

```bash
# In debian, the default configuration will be executed at launch from the file /etc/default/rabbitmq-server
echo 'export RABBITMQ_SERVER_START_ARGS="-kernel inet_dist_listen_min 47000 -kernel inet_dist_listen_max 47500"' >> /etc/default/rabbitmq-server
echo 'export RABBITMQ_CTL_ERL_ARGS="-name rabbit@`hostname` -setcookie RANDOMSTRINGHERE"' >> /etc/default/rabbitmq-server
# Now, we are ready to start our engines
/etc/init.d/rabbitmq-server restart
```

Repeat the process for each remaining RabbitMQ server, remember that all must have the same cookie and the same open ports for internal communication.


### Queue Clustering

You'll now have both servers installed but as separate RabbitMQ instances, we need to tell them to act as one, and also clarify which queues we want them to replicate. In this case, our first server "server1.domain.com" will be the master, and "server2.domain.com" will be the slave, in case server1 falls down the second one will automatically become the new master, and the other one will become a slave once it gets back online.

```bash
# You must run this on the slave server (server2), of course use your own hostnames
rabbitmqctl stop_app
rabbitmqctl join_cluster rabbit@server1.domain.com
rabbitmqctl start_app
rabbitmqctl cluster_status
```

On the last command you must see that this server is joined to a cluster with server1.domain.com and you will be able to check that on cluster_status on the other server as well, there's no need to do anything else on the master machine, but you will need to add all other slaves in case you have more than 1. 

You'll find more tips about adding, checking or removing nodes from a cluster in the [RabbitMQ Clusting](http://www.rabbitmq.com/clustering.html#breakup) documentation website.


### Mirroring Queues

You may do this using the CLI command line script; or via the web-management service. If you want to use the web management, remember to [activate the management plugin](https://www.rabbitmq.com/management.html) first.

You'll find examples on how to synchronize all or some queues using regular expressions in the [High Availability](https://www.rabbitmq.com/ha.html#eager-synchronisation) documentation webpage. We recommend to add the _ha-all_ policy on every queue to avoid issues and to have an easier load balancing setup using ELB.


### Load Balancing both nodes

Now, if you're on Amazon AWS, you only need to create an ELB load balancer for TCP port 5672 and point all your software to the ELB address. It's important to clarify that the ELB must be able to connect to the Queue using TCP port 5672, and because of how ELB works the port will be left open for the world, so make sure to use secure passwords and to delete the default guest username.

In case you're not on Amazon you could use a service like *HAproxy* or manually deciding whether you're going to connect to the first one or the second one on your scripts and apps. Using a non-balanced setup is not recommended but might be easier for you to setup.

That's all for now, have fun queuing!


### Some stuff to keep in mind

* All cluster nodes must have the same version of RabbitMQ and Erlang, it's best not to use the apt/yum repository and install manually using deb/rpm packages to avoid unwanted updates on only one of the nodes which would break the replication.
* Only the queues with the high-availability policy will be synced among the cluster. You can filter the regular expressions or use separate virtual host if you need to have some non-synced queues (only existing in one node).
* In this tutorial we will use hostnames to join both servers, it's not recommended to use Amazon hostnames since they change each time you stop/start the instance (unless it has an Elastic IP, or is part of a VPC). Our recommendation is to use Route53 zones with the EC2 hostname as a CNAME; this will automatically point you to the local or external IP address depending your location.
* Erlang cookies must be the same between all servers in the cluster. Check that all occurrences of the .erlang.cookie file have the same encoded string, you may find those at /root/, /home/user/, and /var/lib/rabbitmq/. It's best to set your cookie with a lauch parameter to avoid misconfiguration.


### Some recommendations to test the replication would be these:

* Try shutting down and/or blocking the network between the server queues while you're pushing / pulling stuff to check it's resilience. In case you're using noAck=true requests, the server might lose pushed information that wasn't synced or give you repeated information if the server from which you've pulled haven't passed that request to the other one.
* Check that your scripts notice when any server goes down and if it will reconnect to it automatically. Also check what will happen when the queue sends you repeated information, or if you need to re-push information.
* Try to push / pull at the same time, at least 2 times above your normal usage frame, so you'll know if it will stay with you on emergency situations and you'll also be aware of it's scalability.
