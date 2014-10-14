#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre CENTOS7
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de desinstalacion de OS para Centos 7
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador en su directorio"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

clear

echo "Bajando y desactivando Servicios de OpenStack"

/usr/local/bin/openstack-control.sh stop
/usr/local/bin/openstack-control.sh disable
service mongod stop
chkconfig mongod off
killall -9 -u mongodb
killall -9 mongod
killall -9 dnsmasq

echo "Eliminando Paquetes de OpenStack"

yum -y erase openstack-glance \
	openstack-utils \
	openstack-selinux \
	openstack-keystone \
	python-psycopg2 \
	qpid-cpp-server \
	qpid-cpp-server-ssl \
	qpid-cpp-client \
	scsi-target-utils \
	sg3_utils \
	openstack-cinder \
	openstack-neutron \
	openstack-neutron-* \
	openstack-nova-* \
	openstack-swift-* \
	openstack-ceilometer-* \
	openstack-heat-* \
	openstack-trove-* \
	mongodb-server \
	mongodb \
	haproxy \
	rabbitmq-server \
	erlang-* \
	openstack-dashboard \
	openstack-packstack \
	sysfsutils \
	genisoimage \
	libguestfs \
	spice-html5 \
	rabbitmq-server \
	python-django-openstack-auth \
	python-keystone* \
	python-backports \
	python-backports-ssl_match_hostname \
	scsi-target-utils \
	scsi-target-utils-gluster

yum -y erase openstack-puppet-modules openstack-packstack-puppet
yum -y erase qpid-cpp-server qpid-cpp-server-ssl qpid-cpp-client cyrus-sasl cyrus-sasl-md5 cyrus-sasl-plain
yum -y erase rabbitmq-server

if [ $cleanupdeviceatuninstall == "yes" ]
then
	rm -rf /srv/node/$swiftdevice/accounts
	rm -rf /srv/node/$swiftdevice/containers
	rm -rf /srv/node/$swiftdevice/objects
	rm -rf /srv/node/$swiftdevice/tmp
	chown -R root:root /srv/node/
	restorecon -R /srv
fi

echo "Eliminando Usuarios de Servicios de OpenStack"

userdel -f -r keystone
userdel -f -r glance
userdel -f -r cinder
userdel -f -r neutron
userdel -f -r nova
userdel -f -r mongodb
userdel -f -r ceilometer
userdel -f -r swift
userdel -f -r rabbitmq
userdel -f -r heat
userdel -f -r trove
userdel -f -r qpidd

echo "Eliminando Archivos remanentes"

rm -fr /etc/glance \
	/etc/keystone \
	/var/log/glance \
	/var/log/keystone \
	/var/lib/glance \
	/var/lib/keystone \
	/etc/cinder \
	/var/lib/cinder \
	/var/log/cinder \
	/etc/sudoers.d/cinder \
	/etc/tgt \
	/etc/neutron \
	/var/lib/neutron \
	/var/log/neutron \
	/etc/sudoers.d/neutron \
	/etc/nova \
	/etc/heat \
	/etc/trove \
	/var/log/trove \
	/var/cache/trove \
	/var/log/nova \
	/var/lib/nova \
	/etc/sudoers.d/nova \
	/etc/openstack-dashboard \
	/var/log/horizon \
	/etc/sysconfig/mongod \
	/var/lib/mongodb \
	/etc/ceilometer \
	/var/log/ceilometer \
	/var/lib/ceilometer \
	/etc/ceilometer-collector.conf \
	/etc/swift/ \
	/var/lib/swift \
	/tmp/keystone-signing-swift \
	/etc/openstack-control-script-config \
	/var/lib/keystone-signing-swift \
	/var/lib/rabbitmq \
	/var/log/rabbitmq \
	/etc/rabbitmq \
	$dnsmasq_config_file \
	/etc/dnsmasq-neutron.d \
	/var/tmp/packstack \
	/var/lib/keystone-signing-swift \
	/var/lib/qpidd \
	/etc/qpid


service crond restart

rm -f /root/keystonerc_admin
rm -f /root/ks_admin_token
rm -f /usr/local/bin/openstack-control.sh
rm -f /usr/local/bin/openstack-log-cleaner.sh
rm -f /usr/local/bin/openstack-keystone-tokenflush.sh
rm -f /usr/local/bin/openstack-vm-boot-start.sh
rm -f /etc/httpd/conf.d/openstack-dashboard.conf*
rm -f /etc/httpd/conf.d/rootredirect.conf*
rm -f /etc/cron.d/keystone-flush.crontab


if [ $snmpinstall == "yes" ]
then
	if [ -f /etc/snmp/snmpd.conf.pre-openstack ]
	then
		rm -f /etc/snmp/snmpd.conf
		mv /etc/snmp/snmpd.conf.pre-openstack /etc/snmp/snmpd.conf
		service snmpd restart
	else
		service snmpd stop
		yum -y erase net-snmp
		rm -rf /etc/snmp
	fi
	rm -f /usr/local/bin/vm-number-by-states.sh \
	/usr/local/bin/vm-total-cpu-and-ram-usage.sh \
	/usr/local/bin/vm-total-disk-bytes-usage.sh \
	/usr/local/bin/node-cpu.sh \
	/usr/local/bin/node-memory.sh \
	/etc/cron.d/openstack-monitor.crontab \
	/var/tmp/node-cpu.txt \
	/var/tmp/node-memory.txt \
	/var/tmp/vm-cpu-ram.txt \
	/var/tmp/vm-disk.txt \
	/var/tmp/vm-number-by-states.txt
fi

echo "Reiniciando Apache sin archivos del Dashboard"

service httpd restart
service memcached restart

echo "Limpiando IPTABLES"

service iptables stop
echo "" > /etc/sysconfig/iptables

if [ $dbinstall == "yes" ]
then

	echo ""
	echo "Desinstalando software de Base de Datos"
	echo ""
	case $dbflavor in
	"mysql")
		service mysqld stop
		sync
		sleep 5
		sync
		yum -y erase mysql-server mysql mariadb-galera-server mariadb-galera-common mariadb-galera galera
		userdel -r mysql
		rm -f /root/.my.cnf /etc/my.cnf
		;;
	"postgres")
		service postgresql stop
		sync
		sleep 5
		sync
		yum -y erase postgresql-server
		userdel -r postgres
		rm -f /root/.pgpass
		;;
	esac
fi

echo ""
echo "Desinstalación completada"
echo ""

