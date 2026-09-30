#!/bin/bash
grep -vw rootkit /etc/hosts > /root/hosts.tmp
echo "192.245.1.1 rootkit.K68.com rootkit" >> /root/hosts.tmp
cat /root/hosts.tmp > /etc/hosts
