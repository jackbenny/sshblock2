SSH Block 2
===========

This is version 2 of my old SSH Block script.

A quick list of what has changed with version 2:
------------------------------------------------
- Total re-write of the code
- No more catting back and forth thruogh the script
- No more strange temp files in /var/state/ssh\_block
- ONE scriptfile for all system (Linux, FreeBSD, Solaris and Mac OS X)
- No more un-neccesary grepping. The script only "greps" if the size of the
log file has changed. This way it uses less system recuorces.
- The blocked IP's are now inserted directly into hosts.deny

History
-------
I came up with ideea of making a version two since I made the port to Solaris
and Mac OS X. I liked the code that came out of these two ports. Later on I
started thinking about what can be done about the script re-writing 
the hosts.deny file every 10th second. 
So for this I added the logfile size check.
And I didn't like having 4 diffrent versions (5 if you count the iptable 
version) of the script. So I made a "One for all" version.

This is the new SSH Block, simply called sshblock2.
It sould run out of the box on FreeBSD, Mac OS X, Linux and Solaris, though
there are some extra steps to make it work with Solaris (since TCP Wrappers
arn't enabled by default and no logging is done.)

Usage
-----
Simply running the script as root should work out of the box. The script will
then search the logfiles and insert the IP-number of any offending host
(SSH-probing hosts) in your systems hosts.deny. Note that your system must
be using TCP Wrappers for this to work (most Linux systems do).

Note to Solaris users
---------------------

There are some things you have to do to your system before this script
will acually work under Solaris.
To start with, TCP Wrappers is not enabled by default on Solaris 10. How to
enable TCP Wrappers and some info about it can be found here:
http://www.sun.com/bigadmin/content/submitted/tcp_wrap_solaris10.html

Second, you have to enable syslog logging of the ssh daemon. This is done by
editing /etc/syslog.conf.
Adding the following line will have sshd logging to /var/log/authlog

auth.info /var/log/authlog

Now you can run the script (as root) and it will block IP numbers of probing
hosts. The scripts will add this hosts to your /etc/hosts.deny file like this:

#BEGIN_SSHBLOCK
sshd : 192.168.0.1
sshd : 10.0.0.3
#END_SSHBLOCK

I would recommend to backup your /etc/hosts.deny and your /etc/syslog.conf
before making changes and running the script.
