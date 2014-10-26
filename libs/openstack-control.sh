#!/bin/bash
#
# Instalador desatendido para Openstack sobre CENTOS7
# Reynaldo R. Martinez P.
# E-Mail: TigerLinux@Gmail.com
#
# Script de control de servicios para OpenStack
#
#

PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

if [ ! -d /etc/openstack-control-script-config ]
then
	echo ""
	echo "No encuento mi directorio de control: /etc/openstack-control-script-config"
	echo "Abortando !"
	echo ""
	exit 0
fi

if [ -f /etc/openstack-control-script-config/nova-console-svc ]
then
	consolesvc=`/bin/cat /etc/openstack-control-script-config/nova-console-svc`
fi

keystone_svc_start='openstack-keystone'

swift_svc_start='
	openstack-swift-account
	openstack-swift-container
	openstack-swift-object
	openstack-swift-proxy
'

glance_svc_start='
	openstack-glance-registry
	openstack-glance-api
'

cinder_svc_start='
	openstack-cinder-api
	openstack-cinder-scheduler
	openstack-cinder-volume
'

heat_svc_start='
	openstack-heat-api
	openstack-heat-api-cfn
	openstack-heat-engine
'

trove_svc_start='
	openstack-trove-api
	openstack-trove-taskmanager
	openstack-trove-conductor
'

sahara_svc_start='
	openstack-sahara-all
'

if [ -f /etc/openstack-control-script-config/neutron-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/neutron-full-installed-metering ]
	then
		metering="neutron-metering-agent"
	else
		metering=""
	fi
	if [ -f /etc/openstack-control-script-config/neutron-full-installed-vpnaas ]
	then
		neutron_svc_start="
			neutron-ovs-cleanup
			neutron-openvswitch-agent
			neutron-metadata-agent
			neutron-l3-agent
			neutron-dhcp-agent
			neutron-lbaas-agent
			neutron-vpn-agent
			$metering
			neutron-server
		"
	else
		neutron_svc_start="
                        neutron-ovs-cleanup
                        neutron-openvswitch-agent
                        neutron-metadata-agent
                        neutron-l3-agent
                        neutron-dhcp-agent
                        neutron-lbaas-agent
			$metering
                        neutron-server
		"
	fi
else
	neutron_svc_start='
		neutron-ovs-cleanup
		neutron-openvswitch-agent
	'
fi

if [ -f /etc/openstack-control-script-config/nova-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/nova-without-compute ]
	then
		nova_svc_start="
			openstack-nova-api
			openstack-nova-cert
			openstack-nova-scheduler
			openstack-nova-conductor
			openstack-nova-consoleauth
			$consolesvc
		"
	else
		nova_svc_start="
			openstack-nova-api
			openstack-nova-cert
			openstack-nova-scheduler
			openstack-nova-conductor
			openstack-nova-consoleauth
			$consolesvc
			openstack-nova-compute
		"
	fi
else
	nova_svc_start='
		openstack-nova-compute
	'
fi

if [ -f /etc/openstack-control-script-config/ceilometer-installed-alarms ]
then
	alarm1="openstack-ceilometer-alarm-notifier"
	alarm2="openstack-ceilometer-alarm-evaluator"
else
	alarm1=""
	alarm2=""
fi

if [ -f /etc/openstack-control-script-config/ceilometer-full-installed ]
then
	if [ -f /etc/openstack-control-script-config/ceilometer-without-compute ]
	then
		ceilometer_svc_start="
			openstack-ceilometer-central
			openstack-ceilometer-api
			openstack-ceilometer-collector
			openstack-ceilometer-notification
			$alarm1
			$alarm2
		"
	else
		ceilometer_svc_start="
			openstack-ceilometer-compute
			openstack-ceilometer-central
			openstack-ceilometer-api
			openstack-ceilometer-collector
			openstack-ceilometer-notification
			$alarm1
			$alarm2
		"
	fi
else
	ceilometer_svc_start="
		openstack-ceilometer-compute
	"
fi



service_status_stop=`echo $service_status_start_enable_disable|tac -s' '`

keystone_svc_stop='openstack-keystone'
swift_svc_stop=`echo $swift_svc_start|tac -s' '`
glance_svc_stop=`echo $glance_svc_start|tac -s' '`
cinder_svc_stop=`echo $cinder_svc_start|tac -s' '`
neutron_svc_stop=`echo $neutron_svc_start|tac -s' '`
nova_svc_stop=`echo $nova_svc_start|tac -s' '`
ceilometer_svc_stop=`echo $ceilometer_svc_start|tac -s' '`
heat_svc_stop=`echo $heat_svc_start|tac -s' '`
trove_svc_stop=`echo $trove_svc_start|tac -s' '`
sahara_svc_stop=`echo $sahara_svc_start|tac -s' '`


case $1 in

start)

	echo ""
	echo "Arrancando Servicios de Openstack"
	echo ""

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_start
                do
                        service $i start
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_start
                do
                        service $i start
                        #sleep 1
                done
        fi

	echo ""

	;;

stop)

	echo ""
	echo "Deteniendo Servicios de OpenStack"
	echo ""

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_stop
                do
                        service $i stop
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi


        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_stop
                do
                        service $i stop
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	rm -rf /tmp/keystone-signing-*
	rm -rf /tmp/cd_gen_*
	if [ -d /var/cache/trove ]
	then
		rm -f /var/cache/trove/*
	fi

	echo ""

	;;

status)

	echo ""
	echo "Verificando estado de los servicios de OpenStack"
	echo ""


	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_start
		do
			service $i status
		done
	fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_start
		do
			service $i status
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_start
                do
                        service $i status
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_start
		do
			service $i status
		done
	fi

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_start
                do
                        service $i status
                done
        fi

	echo ""
	;;

enable)

	echo ""
	echo "Activando arranque automatico de servicios de OpenStack"
	echo ""

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_start
		do
			chkconfig $i on
		done
	fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_start
		do
			chkconfig $i on
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_start
                do
                        chkconfig $i on
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_start
		do
			chkconfig $i on
		done
	fi

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_start
                do
                        chkconfig $i on
                done
        fi

	echo ""
	;;

disable)

	echo ""
        echo "Desactivando arranque automatico de servicios de OpenStack"
        echo ""

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_start
		do
			chkconfig $i off
		done
	fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_start
		do
			chkconfig $i off
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_start
                do
                        chkconfig $i off
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_start
		do
			chkconfig $i off
		done
	fi

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_start
                do
                        chkconfig $i off
                done
        fi

        echo ""
	;;

restart)

	echo ""
	echo "Reiniciando Servicios de OpenStack"
	echo ""

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_stop
                do
                        service $i stop
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_stop
                do
                        service $i stop
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_stop
		do
			service $i stop
			#sleep 1
		done
	fi

	rm -rf /tmp/keystone-signing-*
	rm -rf /tmp/cd_gen_*
        if [ -d /var/cache/trove ]
        then
                rm -f /var/cache/trove/*
        fi

	if [ -f /etc/openstack-control-script-config/keystone ]
	then
		for i in $keystone_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/swift ]
	then
		for i in $swift_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/glance ]
	then
		for i in $glance_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/cinder ]
	then
		for i in $cinder_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/neutron ]
	then
		for i in $neutron_svc_start
		do
			service $i start
			#sleep 1
		done
                if [ -f /etc/openstack-control-script-config/neutron-full-installed ]
                then
                        sleep 5
                        service neutron-l3-agent restart
                        service neutron-dhcp-agent restart
                fi
	fi

	if [ -f /etc/openstack-control-script-config/nova ]
	then
		for i in $nova_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

	if [ -f /etc/openstack-control-script-config/ceilometer ]
	then
		for i in $ceilometer_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

        if [ -f /etc/openstack-control-script-config/heat ]
        then
                for i in $heat_svc_start
                do
                        service $i start
                        #sleep 1
                done
        fi

	if [ -f /etc/openstack-control-script-config/trove ]
	then
		for i in $trove_svc_start
		do
			service $i start
			#sleep 1
		done
	fi

        if [ -f /etc/openstack-control-script-config/sahara ]
        then
                for i in $sahara_svc_start
                do
                        service $i start
                        #sleep 1
                done
        fi

	echo ""

	;;

*)
	echo ""
	echo "Modo de uso: $0 start, stop, status, restart, enable, o disable:"
	echo "start:    Arranca todos los servicios de OpenStack"
	echo "stop:     Detiene todos los servicios de OpenStack"
	echo "restart:  Reinicia en orden todos los servicios de OpenStack"
	echo "enable:   Activa el arranque automatico de todos los servicios de OpenStack"
	echo "disable:  Desactiva el arranque automatico de todos los servicios de OpenStack"
	echo "status:   Muestra el estado de los servicios de OpenStack"
	echo ""
	;;

esac
