#!/bin/bash
#
# Instalador desatendido para Openstack Juno sobre CENTOS7
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
# Octubre del 2014
#
# Script de instalacion y preparacion de Trove
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

if [ -f /etc/openstack-control-script-config/trove-installed ]
then
	echo ""
	echo "Este módulo ya fue ejecutado de manera exitosa - saliendo"
	echo ""
	exit 0
fi


echo ""
echo "Instalando paquetes para Trove"

yum install -y openstack-trove-api \
	openstack-trove \
	openstack-trove-common \
	openstack-trove-taskmanager \
	openstack-trove-conductor \
	python-troveclient \
	python-trove \
	openstack-utils \
	openstack-selinux

echo "Listo"
echo ""

cat ./libs/openstack-config > /usr/bin/openstack-config

source $keystone_admin_rc_file

echo ""
echo "Configurando Trove"
echo ""

cat /usr/share/trove/trove-dist-paste.ini > /etc/trove/api-paste.ini

chown trove.trove /etc/trove/api-paste.ini

commonfile="/etc/trove/trove.conf
	/etc/trove/trove-taskmanager.conf
	/etc/trove/trove-conductor.conf
"

for myconffile in $commonfile
do
	# Failsafe por si el archivo no está !!!
	echo "#" >> $myconffile

	case $dbflavor in
	"mysql")
		openstack-config --set $myconffile DEFAULT sql_connection mysql://$trovedbuser:$trovedbpass@$dbbackendhost:$mysqldbport/$trovedbname
		;;
	"postgres")
		openstack-config --set $myconffile DEFAULT sql_connection postgresql://$trovedbuser:$trovedbpass@$dbbackendhost:$psqldbport/$trovedbname
		;;
	esac

	openstack-config --set $myconffile DEFAULT log_dir /var/log/trove
	openstack-config --set $myconffile DEFAULT verbose False
	openstack-config --set $myconffile DEFAULT debug False
	openstack-config --set $myconffile DEFAULT control_exchange trove
	openstack-config --set $myconffile DEFAULT trove_auth_url http://$keystonehost:5000/v2.0
	openstack-config --set $myconffile DEFAULT nova_compute_url http://$novahost:8774/v2
	openstack-config --set $myconffile DEFAULT cinder_url http://$cinderhost:8776/v1
	openstack-config --set $myconffile DEFAULT swift_url http://$swifthost:8080/v1/AUTH_
	openstack-config --set $myconffile DEFAULT notifier_queue_hostname $messagebrokerhost

	case $brokerflavor in
	"qpid")
        	openstack-config --set $myconffile DEFAULT rpc_backend trove.openstack.common.rpc.impl_qpid
	        openstack-config --set $myconffile DEFAULT qpid_reconnect_interval_min 0
	        openstack-config --set $myconffile DEFAULT qpid_username $brokeruser
	        openstack-config --set $myconffile DEFAULT qpid_tcp_nodelay True
	        openstack-config --set $myconffile DEFAULT qpid_protocol tcp
	        openstack-config --set $myconffile DEFAULT qpid_hostname $messagebrokerhost
	        openstack-config --set $myconffile DEFAULT qpid_password $brokerpass
	        openstack-config --set $myconffile DEFAULT qpid_port 5672
	        openstack-config --set $myconffile DEFAULT qpid_topology_version 1
        	;;

	"rabbitmq")
	        openstack-config --set $myconffile DEFAULT rpc_backend trove.openstack.common.rpc.impl_kombu
        	openstack-config --set $myconffile DEFAULT rabbit_host $messagebrokerhost
	        openstack-config --set $myconffile DEFAULT rabbit_userid $brokeruser
	        openstack-config --set $myconffile DEFAULT rabbit_password $brokerpass
	        openstack-config --set $myconffile DEFAULT rabbit_port 5672
	        openstack-config --set $myconffile DEFAULT rabbit_use_ssl false
	        openstack-config --set $myconffile DEFAULT rabbit_virtual_host $brokervhost
		openstack-config --set $myconffile DEFAULT notifier_queue_userid $brokeruser
		openstack-config --set $myconffile DEFAULT notifier_queue_password $brokerpass
		openstack-config --set $myconffile DEFAULT notifier_queue_ssl false
		openstack-config --set $myconffile DEFAULT notifier_queue_port 5672
		openstack-config --set $myconffile DEFAULT notifier_queue_virtual_host $brokervhost
		openstack-config --set $myconffile DEFAULT notifier_queue_transport memory
        	;;
	esac

done

openstack-config --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_user $keystoneadminuser
openstack-config --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_pass $keystoneadminpass
openstack-config --set /etc/trove/trove-taskmanager.conf DEFAULT nova_proxy_admin_tenant_name $keystoneadmintenant


case $dbflavor in
"mysql")
	openstack-config --set /etc/trove/trove.conf DEFAULT default_datastore mysql
	;;
"postgres")
	openstack-config --set /etc/trove/trove.conf DEFAULT default_datastore postgresql
	;;
esac
openstack-config --set /etc/trove/trove.conf DEFAULT add_addresses True
openstack-config --set /etc/trove/trove.conf DEFAULT network_label_regex "^NETWORK_LABEL$"
openstack-config --set /etc/trove/trove.conf DEFAULT api_paste_config /etc/trove/api-paste.ini
openstack-config --set /etc/trove/trove.conf DEFAULT bind_host 0.0.0.0
openstack-config --set /etc/trove/trove.conf DEFAULT bind_port 8779

troveworkers=`grep processor.\*: /proc/cpuinfo |wc -l`

openstack-config --set /etc/trove/trove.conf DEFAULT trove_api_workers $troveworkers

openstack-config --set /etc/trove/api-paste.ini filter:authtoken admin_tenant_name $troveuser
openstack-config --set /etc/trove/api-paste.ini filter:authtoken admin_user $troveuser
openstack-config --set /etc/trove/api-paste.ini filter:authtoken admin_password $trovepass
openstack-config --set /etc/trove/api-paste.ini filter:authtoken auth_host $keystonehost
openstack-config --set /etc/trove/api-paste.ini filter:authtoken auth_port 35357
openstack-config --set /etc/trove/api-paste.ini filter:authtoken auth_protocol http
openstack-config --set /etc/trove/api-paste.ini filter:authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/trove/api-paste.ini filter:authtoken identity_uri http://$keystonehost:35357
openstack-config --set /etc/trove/api-paste.ini filter:authtoken signing_dir /var/cache/trove

openstack-config --set /etc/trove/trove.conf keystone_authtoken admin_tenant_name $troveuser
openstack-config --set /etc/trove/trove.conf keystone_authtoken admin_user $troveuser
openstack-config --set /etc/trove/trove.conf keystone_authtoken admin_password $trovepass
openstack-config --set /etc/trove/trove.conf keystone_authtoken auth_host $keystonehost
openstack-config --set /etc/trove/trove.conf keystone_authtoken auth_port 35357
openstack-config --set /etc/trove/trove.conf keystone_authtoken auth_protocol http
openstack-config --set /etc/trove/trove.conf keystone_authtoken auth_uri http://$keystonehost:5000/v2.0/
openstack-config --set /etc/trove/trove.conf keystone_authtoken identity_uri http://$keystonehost:35357
openstack-config --set /etc/trove/trove.conf keystone_authtoken signing_dir /var/cache/trove


mkdir -p /var/cache/trove
chown -R trove.trove /var/cache/trove
chmod 700 /var/cache/trove

touch /var/log/trove/trove-manage.log
chown trove.trove /var/log/trove/*

echo ""
echo "Trove Configurado"
echo ""

#
# Se aprovisiona la base de datos
echo ""
echo "Aprovisionando/inicializando BD de TROVE"
echo ""

su -s /bin/sh -c "trove-manage db_sync" trove

case $dbflavor in
"mysql")
	echo ""
	echo "Creando datastore de TROVE en MySQL"
	echo ""
	su -s /bin/sh -c "trove-manage datastore_update mysql ''" trove
	;;
"postgres")
	echo ""
	echo "Creando datastore de TROVE en PostgreSQL"
	echo ""
	su -s /bin/sh -c "trove-manage datastore_update postgresql ''" trove
	;;
esac

echo ""
echo "Listo"
echo ""

echo ""
echo "Aplicando reglas de IPTABLES"

iptables -A INPUT -p tcp -m multiport --dports 8779 -j ACCEPT
service iptables save

echo "Listo"

echo ""
echo "Activando Servicios"
echo ""

service openstack-trove-api start
service openstack-trove-taskmanager start
service openstack-trove-conductor start
chkconfig openstack-trove-api on
chkconfig openstack-trove-taskmanager on
chkconfig openstack-trove-conductor on

testtrove=`rpm -qi openstack-trove-common|grep -ci "is not installed"`
if [ $testtrove == "1" ]
then
	echo ""
	echo "Falló la instalación de trove - abortando el resto de la instalación"
	echo ""
	exit 0
else
	date > /etc/openstack-control-script-config/trove-installed
	date > /etc/openstack-control-script-config/trove
fi


echo ""
echo "Trove Instalado"
echo ""

