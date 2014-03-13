---
layout: post
title: Centralize your logs with Graylog2
tags: [graylog2, gelf, linux, debian]
author: kuteninja
---

[Graylog2](http://graylog2.org/) is an open source log management solution used to store logs in [ElasticSearch](http://www.elasticsearch.org/) and perform data analysis. It consists of a server application written in Java that accepts Syslog and GELF messages via TCP, UDP or AMQP and stores them in the database. The second part is a web interface that allows you to manage those indexed messages; there you can search patterns, create charts, send reports and be alerted when something happens.


### Why Graylog2

Graylog2 is fast, open source, free (both as "free beer" and "freedom"), and it also have a lot of pre-built integrations for apps made with Java, Node.JS, Ruby, .Net, Perl, PHP, Go, C++ and many more.

In case you have a cluster with many servers that work on similar tasks, it's extremely useful to have all the workers logs on the same server to look for different patterns or check for errors without having to do this on each server and having to fight with sed, egrep, awk and some other features that DevOps have found to both love and hate.

It have two specific features which are remote Syslog and GELF. The first one is useful for system messages (ie kernel, firewall, various daemons), and the second one should be used for logging within applications. Also, you can use the REST API and HTTP GELF to build custom tools and entry points.


### Preparing the server before the setup

First of all you'll need a dedicated server or a vps for the log server; keep in mind that it's going to need a lot of CPU if you send lots of messages per minute to it, so don't skimp on resources for it. We're using an c3.large EC2 machine on Amazon AWS, it might be a good start for you, unless you have less than 100 logfiles to index.

In this case we are going to install it on a Debian 7 "Wheezy" with 64 bits, if you have the same distro, it might be easy to just copy and paste all the following commands to get it running. Check the comments on the following code for tips or help in case it doesn't work for you as is.

```bash
# 1st: Become root (if needed)
if [ "$(whoami)" != "root" ]; then sudo su -; fi
# 2nd: Setup MongoDB 10gen (>2.4)
apt-key adv --keyserver keyserver.ubuntu.com --recv 7F0CEB10
echo 'deb http://downloads-distro.mongodb.org/repo/debian-sysvinit dist 10gen' | sudo tee /etc/apt/sources.list.d/mongodb.list
apt-get update
apt-get remove mongodb mongodb-clients mongodb-server
apt-get install mongodb-10gen
# 3rd: Setup Java OpenJDK 7
apt-get remove -y sun-java6-bin  sun-java6-jdk sun-java6-jre
apt-get install openjdk-7-jre
# 4th: Setup ElasticSearch 0.90 (it must be 0.9.0 for Graylog2 0.20.1)
wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.12.deb
dpkg -i elasticsearch-0.90.12.deb
# 5th: Change cluster.name to graylog2 (/etc/elasticsearch/elasticsearch.yml) and restart
sed -i "s/^cluster.name:.*/cluster.name: graylog2/" /etc/elasticsearch/elasticsearch.yml
/etc/init.d/elasticsearch restart
```

### Installing Graylog2 Server

We are going to use .deb packages to avoid the software to get automatically updated since it might break if there's an incompatible ElasticSearch version running next to it. In case you're OS is not Debian based, you should search for the packages that fit your OS (ie rpm / tar.gz).

```bash
# 1st: Become root (if needed)
if [ "$(whoami)" != "root" ]; then sudo su -; fi
# 2nd: Download and Install Graylog2 from https://gist.github.com/hggh/7492598
wget http://finja.brachium-system.net/~jonas/packages/graylog2/graylog2-server_0.20.1-1_all.deb
wget http://finja.brachium-system.net/~jonas/packages/graylog2/graylog2-stream-dashboard_0.90.0-1_all.deb
wget http://finja.brachium-system.net/~jonas/packages/graylog2/graylog2-web_0.20.1-1_all.deb
apt-get install uuid-runtime pwgen
dpkg -i graylog2-server_0.20.1-1_all.deb graylog2-web_0.20.1-1_all.deb graylog2-stream-dashboard_0.90.0-1_all.deb
# 3rd: Enable the init files
sed -i 's@no@yes@' /etc/default/graylog2-server
sed -i 's@no@yes@' /etc/default/graylog2-web
# 4th: Change graylog2-server.uris so that it points to localhost
sed -i "s/graylog2-server.uris=.*/graylog2-server.uris=\"http:\/\/127.0.0.1:12900\//" /etc/graylog2/web/graylog2-web-interface.conf
```

Now, you need to setup a password hash for encryption in general; the easiest way to do it is with pwgen:

```bash 
pwgen -s 96 
```

That will give you a bunch of passwords that you can use for anything. You need to pick one of those, and save it as a **password_secret** at */etc/graylog2/server/server.conf* and place the same one as **application.secret** at */etc/graylog2/web/graylog2-web-interface.conf*

And then you'll need a password to login at the web panel, you can use any password you want encoded with via SHA256. The easiest way to do it is using echo and shasum:

```bash
echo -n 'PasswordHere!' | shasum -a 256
```

You need to save that hash string as the **root\_password\_sha2** at */etc/graylog2/server/server.conf*


### Server Startup

Now, we use the init files to start all the required services. In case your OS doesn't automatically sets them on-boot you might want to do that as well by using chkconfig, rc-config, update-rc.d or systemctl (it may vary depending on the OS you're using).

```bash
/etc/init.d/elasticsearch start
/etc/init.d/graylog2-server start
/etc/init.d/graylog2-web start
```

Now you should be able to login on **http://yourhostname.com:9000** with the user admin and the password you've set on the previous step. You can change the password at any time by just editing the variable **root\_password\_sha2** on the file */etc/graylog2/server/server.conf*


### Testing the service and deploying it for production usage

When you first enter the Graylog2 Web Interface, you'll notice a warning on top saying that this node doesn't have any input sources. Let's fix that.

* Enter on System > Inputs
* Launch a new GELF TCP / UDP socket (port 12201 by default)
* Launch a new GELF HTTP on a port 12202
* You can also launch a Syslog UDP / TCP socket on a separate port if you want to use one of those.
* Now you can use the following cURL request to send a test message to the server:

```bash
curl -XPOST http://yourhostname.com:12202/gelf -p0 -d '{"short_message":"Hello there", "host":"example.org", "facility":"test", "_foo":"bar"}'
```

If you can find *"Hello there"* using the Search panel, and the hostname *"example.org"* listed on the Sources page, you're good to go. To deploy your own logs on your applications it would be best if you check the documentation for the plugin you need, they're listed as [GELF Libraries](http://graylog2.org/gelf#libraries) on the Graylog2 Website. 

Just as a side-note, if you need to log information from a separate software that you can't modify (ie a privative application), you could use the Grok filter from Logstash to process the software log files directly and send them to Graylog2 in a GELF format as well.

There's also a way to get the logfiles from a RabbitMQ Queue using an AMQP source. If you have a [RabbitMQ Cluster](http://42.smx.io/2014/03/06/RabbitMQ-HA-cluster/) it might be a good idea to send the logs there, since in the event that the server goes down the machines will keep logging on the queue server.
