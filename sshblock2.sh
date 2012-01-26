#!/bin/bash

################################################################################
#                                                                              #
#  Copyright (C) 2006 Jack-Benny Persson <jake@cyberinfo.se>                   #
#                                                                              #
#   This program is free software; you can redistribute it and/or modify       #
#   it under the terms of the GNU General Public License as published by       #
#   the Free Software Foundation; either version 2 of the License, or          #
#   (at your option) any later version.                                        #
#                                                                              #
#   This program is distributed in the hope that it will be useful,            #
#   but WITHOUT ANY WARRANTY; without even the implied warranty of             #
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              #
#   GNU General Public License for more details.                               #
#                                                                              #
#   You should have received a copy of the GNU General Public License          #
#   along with this program; if not, write to the Free Software                #
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA  #
#                                                                              #
################################################################################

# Version 2.3
#
# SSH Block 2 - A script that blocks SSH probing hosts in /etc/hosts.deny
# This is version two of SSH Block, wich is a total re-write of the original
# code. This version should work on Linux, FreeBSD, Solaris and Mac OS X.
# Please read the README file for more information.

#If these users are trying to login via SSH, the host is instantly blocked.
#Be careful not to add users that normaly login via SSH here...
BLOCK_USERS=("mysql" "nobody")

SLEEP_TIME=10
OS=`uname`

if [ "$OS" = "FreeBSD" ]; then
        DENYFILE="/etc/hosts.allow" #Both allow and deny in one file on FreeBSD
elif [ "$OS" != "FreeBSD" ]; then
        DENYFILE="/etc/hosts.deny" #The default way...
fi


if [ "$UID" -ne 0 ]; then
        echo "Must be run as root"
        exit 2
fi

#The default way...
print_ip()
{
        sort | uniq | sed -e 's/^/sshd : /' >> ${DENYFILE}
}

#The FreeBSD way...
print_ip_freebsd()
{
        sort | uniq | sed -e 's/^/sshd : /' | sed -e 's/$/ : deny/' >> \
        ${DENYFILE}
}

#Diffrent logfiles with diffrent syntax on diffrent systems...
SunOS_greplog()
{
        grep sshd /var/log/authlog | grep 'invalid user' \
        | awk '{print $15}' - | sort | uniq

        for i in ${BLOCK_USERS[*]}; do grep \
        "Failed keyboard-interactive for $i from" \
        /var/log/authlog; done | awk '{print $14}' - | sort | uniq
}

FreeBSD_greplog()
{
        (grep 'Illegal user' /var/log/auth.log || \
        grep 'Invalid user' /var/log/auth.log) \
        | awk '{print $10}' - | sort | uniq
        
        for i in ${BLOCK_USERS[*]}; do grep "Failed password for $i from" \
        /var/log/auth.log; done | awk '{print $11}' - | sort | uniq
}

OpenBSD_greplog()
{
        grep 'Invalid user' /var/log/authlog \
        | awk '{print $10}' - | sort | uniq
        
        for i in ${BLOCK_USERS[*]}; do grep "Failed password for $i from" \
        /var/log/authlog; done | awk '{print $11}' - | sort | uniq
}

Linux_greplog()
{
        (grep '[Ii]nvalid user' /var/log/messages || \
        grep '[Ii]nvalid user' /var/log/auth.log || \
        grep '[Ii]llegal user' /var/log/secure || \
        grep '[Ii]llegal user' /var/log/messages || \
        grep '[Ii]nvalid user' /var/log/secure) \
        | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' - | sort | uniq

        for i in ${BLOCK_USERS[*]}; do grep \
        "Authentication failure for $i from" \
        /var/log/messages; done | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' \
        - | sort | uniq
        
        for i in ${BLOCK_USERS[*]}; do grep "Failed password for $i from" \
        /var/log/messages; done | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' \
        - | sort | uniq

        for i in ${BLOCK_USERS[*]}; do grep "Failed password for $i from" \
        /var/log/auth.log; done | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' \
        - | sort | uniq
        
        for i in ${BLOCK_USERS[*]}; do grep \
        "Authentication failure for $i from" \
        /var/log/secure; done | egrep -o '[0-9]{1,3}(\.[0-9]{1,3}){3}' \
        - | sort | uniq
}

Darwin_greplog()
{
        grep sshd /var/log/system.log | grep 'illegal user' \
        | awk '{print $15}' - | sort | uniq

        for i in ${BLOCK_USERS[*]}; do grep \
        "Authentication failure for $i from" \
        /var/log/system.log; done |  - | awk '{print $13}' sort | uniq

}

SunOS_size() 
{ 
        ls -l /var/log/authlog | awk '{print $5}' 
}

Darwin_size() 
{ 
        ls -l /var/log/system.log | awk '{print $5}' 
}

FreeBSD_size() 
{ 
        ls -l /var/log/auth.log | awk '{print $5}' 
}

OpenBSD_size() 
{ 
        ls -l /var/log/authlog | awk '{print $5}' 
}

Linux_size()
{
        if [ -e /var/log/secure ] && [ -e /var/log/messages ]; then
                A=`ls -l /var/log/secure | awk '{print $5}'`
                B=`ls -l /var/log/messages | awk '{print $5}'`
                let C=A+B
                echo $C
        elif [ -e /var/log/secure ]; then
                ls -l /var/log/secure | awk '{print $5}'
        elif [ -e /var/log/messages ]; then
                ls -l /var/log/messages | awk '{print $5}'
        fi
}

touch ${DENYFILE}

#Check if we have run SSH Block before....
RUN_BEFORE=`grep -c "#BEGIN_SSHBLOCK" ${DENYFILE}`
if [ $RUN_BEFORE -gt 0 ]; then
        echo "/#BEGIN_SSHBLOCK/,/#END_SSHBLOCK/d|x" \
        | ex -s ${DENYFILE}
fi

OLD_SIZE=0

#Here we go!
(
while true
do
        case "$OS" in
                SunOS) SIZE=`SunOS_size` ;;
                Darwin) SIZE=`Darwin_size` ;;
                FreeBSD) SIZE=`FreeBSD_size` ;;
                OpenBSD) SIZE=`OpenBSD_size` ;;
                Linux) SIZE=`Linux_size` ;;
        esac
        if [ $OLD_SIZE -ne $SIZE ]; then
                
                BLOCK_EXIST=`grep -c "#BEGIN_SSHBLOCK" ${DENYFILE}`
                if [ $BLOCK_EXIST -gt 0 ]; then
                        echo "/#BEGIN_SSHBLOCK/,/#END_SSHBLOCK/d|x" \
                        | ex -s ${DENYFILE}
                fi
                
                echo "#BEGIN_SSHBLOCK" >> ${DENYFILE}
                case "$OS" in
                        SunOS) SunOS_greplog | print_ip ;;
                        FreeBSD) FreeBSD_greplog | print_ip_freebsd ;;
                        OpenBSD) OpenBSD_greplog | print_ip ;;
                        Linux) Linux_greplog | print_ip ;;
                        Darwin) Darwin_greplog | print_ip ;;
                esac
                echo "#END_SSHBLOCK" >> ${DENYFILE}
                case "$OS" in
                        SunOS) OLD_SIZE=`SunOS_size` ;;
                        Darwin) OLD_SIZE=`Darwin_size` ;;
                        FreeBSD) OLD_SIZE=`FreeBSD_size` ;;
                        OpenBSD) OLD_SIZE=`OpenBSD_size` ;;
                        Linux) OLD_SIZE=`Linux_size` ;;
                esac
                sleep ${SLEEP_TIME}
        else
                sleep ${SLEEP_TIME}
        fi
done
) 2> /dev/null &
