#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre CENTOS7
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de pre-requisitos
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ -f ./configs/main-config.rc ]
then
	source ./configs/main-config.rc
	mkdir -p /etc/openstack-control-script-config
else
	echo "No puedo acceder a mi archivo de configuración"
	echo "Revise que esté ejecutando el instalador/módulos en el directorio correcto"
	echo "Abortando !!!!."
	echo ""
	exit 0
fi

#
# Verificaciones y taras de limpieza iniciales para evitar "opppss"
#

rm -rf /tmp/keystone-signing-*
rm -rf /tmp/cd_gen_*

epelinstalled=`rpm -qa|grep epel-release.\*noarch|wc -l`
amiroot=` whoami|grep root|wc -l`
amiarhel7=`cat /etc/redhat-release |grep 7.|wc -l`
internalbridgeinterface=`ifconfig $integration_bridge|grep -c $integration_bridge`
internalbridgepresent=`ovs-vsctl show|grep -i -c bridge.\*$integration_bridge`
oskernelinstalled=`uname -r|grep -c x86_64`

echo ""
echo "NOTA: Desactivando SELINUX - Bug existente con NOVA-API"
echo ""

setenforce 0
sed -r -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config
sed -r -i 's/SELINUX=permissive/SELINUX=disabled/g' /etc/selinux/config

echo ""
	
echo "Instalando paquetes iniciales"
echo ""

# Se instalan las dependencias principales vía yum
#
yum -y clean all
yum -y install yum-plugin-priorities yum-presto yum-plugin-changelog openstack-packstack
yum -y groupinstall Virtualization-Platform Virtualization-tools
yum -y install libvirt qemu kvm
yum -y install sudo gcc cpp make automake kernel-headers
yum -y install python-keystoneclient python-sqlalchemy python-migrate python-psycopg2 \
	MySQL-python python-tools sysfsutils sg3_utils genisoimage libguestfs glusterfs \
	glusterfs-fuse nfs-utils sudo libguestfs-tools-c

yum -y install boost-program-options perl-DBD-MySQL wxBase wxGTK  wxGTK-gl libtool-ltdl \
	unixODBC python-six python-iso8601 python-babel python-argparse python-oslo-config \
	python-ordereddict python-webob python-memcached python-oauthlib python-routes \
	python-backports python-backports-ssl_match_hostname python-urllib3 python-passlib \
	python-dogpile-core python-dogpile-cache python-jsonschema python-paste \
	python-paste-deploy python-tempita python-chardet python-requests python-stevedore

yum -y install PyPAM python-decorator python-migrate python-prettytable python-keyring \
	python-keystoneclient python-greenlet python-eventlet python-oslo-messaging \
	python-pycadf python-keystone python-httplib2 pyxattr python-swiftclient \
	python-kombu python-qpid pysendfile python-jsonpointer python-jsonpatch \
	python-warlock python-glanceclient python-simplejson python-cinderclient \
	saslwrapper python-saslwrapper python-glance crudini libibverbs librdmacm

yum -y install perl-Config-General python-anyjson python-novaclient python-amqplib \
	python-markdown python-oslo-rootwrap python-suds libyaml PyYAML python-pygments \
	python-cheetah pyparsing python-futures python-lockfile python-devel numpy-f2py \
	scipy python-networkx-core python-taskflow python-cinder python-markupsafe \
	python-jinja2 python-pyasn1 python-boto python-cmd2 python-cliff

yum -y install python-neutronclient python-websockify pysnmp python-croniter python-beaker \
	python-mako python-alembic python-ply python-msgpack python-jsonpath-rw \
	python-ceilometer python-libguestfs python-neutron python-ceilometerclient \
	python-troveclient python-versiontools python-bson python-pymongo python-simplegeneric \
	python-logutils python-werkzeug python-flask python-webtest python-ipaddr \
	python-wsme python-singledispatch python-pecan 

yum -y install python-ceilometerclient python-cinderclient python-glanceclient \
	python-heatclient python-openstackclient python-swiftclient python-neutronclient \
	python-novaclient python-configobj python-lesscpy python-netifaces

yum -y install scsi-target-utils scsi-target-utils-gluster

yum -y install libguestfs-tools libguestfs

yum -y erase firewalld
yum -y install iptables iptables-services iptables-utils

yum -y localinstall ./libs/spice-html5-0.1.4-1.el7.noarch.rpm
	
yum -y install tuned tuned-utils
echo "virtual-host" > /etc/tuned/active_profile
chkconfig ksm on
chkconfig ksmtuned on
chkconfig tuned on

service ksm restart
service ksmtuned restart
service tuned restart

testlibvirt=`rpm -qi libvirt|grep -ci "is not installed"`

if [ $testlibvirt == "1" ]
then
	echo ""
	echo "Falló la instalación del prerequisito libvirt - abortando el resto de la instalación"
	echo ""
	exit 0
fi

packstackinstalled=`rpm -qa|grep openstack-packstack.\*noarch|grep -v puppet|wc -l`
searchtestnova=`yum search openstack-nova-common|grep openstack-nova-common.\*noarch|wc -l`


if [ $amiarhel7 == "1" ]
then
	echo ""
	echo "Ejecutando en un RHEL7 o Compatible - continuando"
	echo ""
else
	echo ""
	echo "No se pudo verificar que el sistema operativo es un RHEL7 o Compatible"
	echo "Abortando"
	echo ""
fi

if [ $epelinstalled == "1" ]
then
	echo ""
	echo "Epel Instalado - continuando"
else
	echo ""
	echo "Prerequisito inexistente: Repositorio EPEL no instalado"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $amiroot == "1" ]
then
	echo ""
	echo "Ejecutando como root - continuando"
	echo ""
else
	echo ""
	echo "ALERTA !!!. Este script debe ser ejecutado por el usuario root"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $oskernelinstalled == "1" ]
then
	echo ""
	echo "Kernel OpenStack RDO x86_64 detectado - continuando"
	echo ""
	else
	echo ""
	echo "ALERTA !!!. Este servidor no tiene el Kernel de RDO-Openstack instalado"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $packstackinstalled == "1" ]
then
	echo ""
	echo "Packstack instalado correctamente - continuando"
	echo ""
else
	echo ""
	echo "No se pudo verificar la existencia de Packstack"
	echo "Posible falla con repositorio RDO"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $searchtestnova == "1" ]
then
	echo ""
	echo "Repositorios RDO aparentemente en orden - continuando"
	echo ""
else
	echo ""
	echo "No se pudo verificar el correcto funcionamiento del repo RDO"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $internalbridgeinterface == "1" ]
then
	echo ""
	echo "Interfaz del bridge de integracion Presente - Continuando"
	echo ""
else
	echo ""
	echo "No se pudo encontrar la interfaz del bridge de integracion"
	echo "Abortando"
	echo ""
	exit 0
fi

if [ $internalbridgepresent == "1" ]
then
	echo ""
	echo "Bridge de integracion Presente - Continuando"
	echo ""
else
	echo ""
	echo "No se pudo encontrar el bridge de integracion"
	echo "Abortando"
	echo ""
	exit 0
fi

echo ""
echo "Pre-requisitos iniciales validados"
echo ""

echo "Preparando libvirt y limpiando configuración de IPTABLES"
echo "No se preocupe si ve un mensaje de FAILED"

if [ -f /etc/openstack-control-script-config/libvirt-installed ]
then
	echo "Libvirt y otros prerequisitos ya instalados"
else
	service libvirtd stop
	rm /etc/libvirt/qemu/networks/autostart/default.xml
	rm /etc/libvirt/qemu/networks/default.xml
	service iptables stop
	echo “” > /etc/sysconfig/iptables
	cat ./libs/iptables > /etc/sysconfig/iptables
	service libvirtd start
	chkconfig libvirtd on
	service iptables stop
	service iptables start
	service iptables save
	service iptables restart
	date > /etc/openstack-control-script-config/libvirt-installed
fi

