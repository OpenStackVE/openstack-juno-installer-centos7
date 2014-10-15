#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre CENTOS7
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de Sahara
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

if [ -f /etc/openstack-control-script-config/db-installed ]
then
	echo ""
	echo "Proceso de BD verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende de que el proceso de base de datos"
	echo "haya sido exitoso, pero aparentemente no lo fue"
	echo "Abortando el módulo"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/keystone-installed ]
then
	echo ""
	echo "Proceso principal de Keystone verificado - continuando"
	echo ""
else
	echo ""
	echo "Este módulo depende del proceso principal de keystone"
	echo "pero no se pudo verificar que dicho proceso haya sido"
	echo "completado exitosamente - se abortará el proceso"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/sahara-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi


echo ""
echo "Instalando paquetes para Sahara"

yum install -y openstack-sahara \
	python-saharaclient \
	openstack-utils \
	openstack-selinux

echo "Listo"
echo ""

cat ./libs/openstack-config > /usr/bin/openstack-config

source $keystone_admin_rc_file

echo ""
echo "Configurando Sahara"
echo ""

openstack-config --del /etc/sahara/sahara.conf database connection
openstack-config --del /etc/sahara/sahara.conf database connection
openstack-config --del /etc/sahara/sahara.conf database connection
openstack-config --del /etc/sahara/sahara.conf database connection
openstack-config --del /etc/sahara/sahara.conf database connection

case $dbflavor in
"mysql")
	openstack-config --set /etc/sahara/sahara.conf database connection mysql://$saharadbuser:$saharadbpass@$dbbackendhost:$mysqldbport/$saharadbname
	;;
"postgres")
	openstack-config --set /etc/sahara/sahara.conf database connection postgresql://$saharadbuser:$saharadbpass@$dbbackendhost:$psqldbport/$saharadbname
	;;
esac

openstack-config --set /etc/sahara/sahara.conf DEFAULT debug false
openstack-config --set /etc/sahara/sahara.conf DEFAULT verbose false
openstack-config --set /etc/sahara/sahara.conf DEFAULT log_dir /var/log/sahara
openstack-config --set /etc/sahara/sahara.conf DEFAULT log_file sahara.log
openstack-config --set /etc/sahara/sahara.conf DEFAULT host $saharahost
openstack-config --set /etc/sahara/sahara.conf DEFAULT port 8386
openstack-config --set /etc/sahara/sahara.conf DEFAULT use_neutron true
openstack-config --set /etc/sahara/sahara.conf DEFAULT use_namespaces true
openstack-config --set /etc/sahara/sahara.conf DEFAULT os_region_name $endpointsregion
openstack-config --set /etc/sahara/sahara.conf DEFAULT control_exchange openstack

openstack-config --set /etc/sahara/sahara.conf keystone_authtoken admin_tenant_name $keystoneservicestenant
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken admin_user $saharauser
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken admin_password $saharapass
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken auth_host $keystonehost
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken identity_uri http://$keystonehost:35357
openstack-config --set /etc/sahara/sahara.conf keystone_authtoken signing_dir /tmp/keystone-signing-sahara


case $brokerflavor in
"qpid")
	# openstack-config --set /etc/sahara/sahara.conf DEFAULT rpc_backend sahara.openstack.common.rpc.impl_qpid
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rpc_backend qpid
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_reconnect_interval_min 0
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_username $brokeruser
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_tcp_nodelay True
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_protocol tcp
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_hostname $messagebrokerhost
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_password $brokerpass
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_port 5672
	openstack-config --set /etc/sahara/sahara.conf DEFAULT qpid_topology_version 1
	;;

"rabbitmq")
	# openstack-config --set /etc/sahara/sahara.conf DEFAULT rpc_backend sahara.openstack.common.rpc.impl_kombu
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rpc_backend rabbit
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_host $messagebrokerhost
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_userid $brokeruser
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_password $brokerpass
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_port 5672
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_use_ssl false
	openstack-config --set /etc/sahara/sahara.conf DEFAULT rabbit_virtual_host $brokervhost
	;;
esac

mkdir -p /var/log/sahara
echo "" > /var/log/sahara/sahara.log
chown -R sahara.sahara /var/log/sahara /etc/sahara

echo ""
echo "Sahara Configurado"
echo ""

#
# Se aprovisiona la base de datos
echo ""
echo "Aprovisionando/inicializando BD de SAHARA"
echo ""

sahara-db-manage --config-file /etc/sahara/sahara.conf upgrade head

chown -R sahara.sahara /var/log/sahara /etc/sahara

echo ""
echo "Listo"
echo ""

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 8386 -j ACCEPT
service iptables save

echo "Listo"

echo ""
echo "Activando Servicios"
echo ""

systemctl start openstack-sahara-all
systemctl enable openstack-sahara-all

testsahara=`rpm -qi openstack-sahara|grep -ci "is not installed"`
if [ $testsahara == "1" ]
then
	echo ""
	echo "Falló la instalación de sahara - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/sahara-installed
	date > /etc/openstack-control-script-config/sahara
fi


echo ""
echo "Sahara Instalado"
echo ""



