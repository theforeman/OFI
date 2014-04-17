module Staypuft
  class Service < ActiveRecord::Base
    has_many :role_services, :dependent => :destroy
    has_many :roles, :through => :role_services
    has_many :hostgroups, :through => :roles

    has_many :service_classes, :dependent => :destroy
    has_many :puppetclasses, :through => :service_classes

    attr_accessible :description, :name

    validates  :name, :presence => true, :uniqueness => true

    # for each service, a list of param names. Optionally, instead of a string
    # for a param name, an array of [param_name, puppetclass] in the case where
    # there are possibly multiple puppetclass matches. without this, we'll
    # just grab the first puppetclass from the matching hostgroup
    UI_PARAMS = { 
      "qpid (non-HA)"=> ["qpid_ca", "qpid_cert", "qpid_host", "qpid_key", "qpid_nssdb_password"],
      "MySQL"=> ["mysql_ca", "mysql_cert", "mysql_host", "mysql_key",
                 "mysql_root_password"],
      "Keystone (non-HA)"=> ["keystone_admin_token", "keystone_db_password"],
      "Nova (Controller)"=> ["admin_email", "admin_password", "auto_assign_floating_ip",
                             "controller_admin_host", "controller_priv_host",
                             "controller_pub_host", "freeipa", "horizon_ca",
                             "horizon_cert", "horizon_key", "horizon_secret_key",
                             "nova_db_password", "nova_user_password", "ssl",
                             "swift_admin_password", "swift_ringserver_ip",
                             "swift_shared_secret", "swift_storage_device",
                             "swift_storage_ips"],
      "Neutron (Controller)" => ["admin_email", "admin_password",
                                 "cisco_nexus_plugin", "cisco_vswitch_plugin",
                                 "controller_admin_host", "controller_priv_host",
                                 "controller_pub_host", "enable_tunneling",
                                 "freeipa", "horizon_ca", "horizon_cert",
                                 "horizon_key", "horizon_secret_key",
                                 "ml2_flat_networks", "ml2_install_deps",
                                 "ml2_mechanism_drivers", "ml2_network_vlan_ranges",
                                 "ml2_tenant_network_types", "ml2_tunnel_id_ranges",
                                 "ml2_type_drivers", "ml2_vni_ranges",
                                 "ml2_vxlan_group", "neutron_core_plugin",
                                 "neutron_db_password", "neutron_metadata_proxy_secret",
                                 "neutron_user_password", "nexus_config",
                                 "nexus_credentials", "nova_db_password",
                                 "nova_user_password", "ovs_vlan_ranges",
                                 "provider_vlan_auto_create", "provider_vlan_auto_trunk",
                                 "ssl", "tenant_network_type", "tunnel_id_ranges",
                                 "verbose",
                                 "swift_admin_password", "swift_ringserver_ip",
                                 "swift_shared_secret", "swift_storage_device",
                                 "swift_storage_ips"],
      "Glance (non-HA)"=> ["glance_db_password", "glance_user_password"],
      "Cinder"=> ["cinder_backend_gluster", "cinder_backend_iscsi",
                  "cinder_db_password",
                  "cinder_gluster_volume"],
      "Heat"=> ["heat_cfn", "heat_cloudwatch", "heat_db_password", "heat_user_password"],
      "Ceilometer"=> ["ceilometer_metering_secret", "ceilometer_user_password"
                     ],
      "Neutron - L3" => ["controller_priv_host", "enable_tunneling",
                         "external_network_bridge", "fixed_network_range",
                         "mysql_ca", "mysql_host", "neutron_db_password",
                         "neutron_metadata_proxy_secret", "neutron_user_password",
                         "nova_db_password", "nova_user_password",
                         "qpid_host", "ssl",
                         "tenant_network_type", "tunnel_id_ranges", "verbose"],
      "DHCP" => [],
      "OVS" => ["ovs_bridge_mappings", "ovs_bridge_uplinks",
                "ovs_tunnel_iface", "ovs_tunnel_types", "ovs_vlan_ranges",
                "ovs_vxlan_udp_port" ],
      "Nova-compute" => ["auto_assign_floating_ip",
                         "cinder_backend_gluster", "controller_priv_host",
                         "controller_pub_host", "mysql_host",
                         "qpid_host"],
      "Neutron-compute" => ["admin_password", "ceilometer_metering_secret",
                            "ceilometer_user_password", "cinder_backend_gluster",
                            "controller_admin_host", "controller_priv_host",
                            "controller_pub_host", "enable_tunneling", "mysql_ca",
                            "mysql_host", "neutron_core_plugin",
                            "neutron_db_password", "neutron_user_password",
                            "nova_db_password", "nova_user_password",
                            "ovs_bridge_mappings", "ovs_tunnel_iface",
                            "ovs_tunnel_types", "ovs_vlan_ranges",
                            "ovs_vxlan_udp_port", "qpid_host", "ssl",
                            "tenant_network_type", "tunnel_id_ranges", "verbose"],
      "Neutron-ovs-agent"=> [],
      "Swift" => ["swift_all_ips", "swift_ext4_device", "swift_local_interface",
                  "swift_loopback", "swift_ring_server"],
      "Database (HA -- temp)" => [],
      "Cinder (HA)" => ["db_password", "volume", "volume_backend", "glusterfs_shares"],
      "Nova (HA)" => [["auto_assign_floating_ip", "quickstack::pacemaker::nova"],
                      ["default_floating_pool", "quickstack::pacemaker::nova"],
                      ["force_dhcp_release", "quickstack::pacemaker::nova"]],
      "Glance (HA)" => [["backend", "quickstack::pacemaker::glance"],
                        ["filesystem_store_datadir", "quickstack::pacemaker::glance"],
                        ["db_password", "quickstack::pacemaker::glance"]],
      "qpid (HA)" => [],
      "Memcached (HA)" => [],
      "Load Balancer (HA)" => [],
      "Keystone (HA)" => [["admin_email", "quickstack::pacemaker::keystone"],
                          ["admin_password", "quickstack::pacemaker::keystone"],
                          ["admin_tenant", "quickstack::pacemaker::keystone"],
                          ["admin_token", "quickstack::pacemaker::keystone"],
                          ["keystonerc", "quickstack::pacemaker::keystone"],
                          ["db_password", "quickstack::pacemaker::keystone"]],
      "HA (Controller)"  => [["fence_ipmilan_address", "quickstack::pacemaker::common"],
                             ["fence_ipmilan_interval", "quickstack::pacemaker::common"],
                             ["fence_ipmilan_password", "quickstack::pacemaker::common"],
                             ["fence_ipmilan_username", "quickstack::pacemaker::common"],
                             ["fence_xvm_clu_iface", "quickstack::pacemaker::common"],
                             ["fence_xvm_key_file_password", "quickstack::pacemaker::common"],
                             ["fence_xvm_manage_key_file", "quickstack::pacemaker::common"],
                             ["fencing_type", "quickstack::pacemaker::common"],
                             ["pacemaker_cluster_members", "quickstack::pacemaker::common"],
                             ["cinder_admin_vip", "quickstack::pacemaker::params"],
                             ["cinder_private_vip", "quickstack::pacemaker::params"],
                             ["cinder_public_vip", "quickstack::pacemaker::params"],
                             ["db_vip", "quickstack::pacemaker::params"],
                             ["glance_admin_vip", "quickstack::pacemaker::params"],
                             ["glance_private_vip", "quickstack::pacemaker::params"],
                             ["glance_public_vip", "quickstack::pacemaker::params"],
                             ["heat_admin_vip", "quickstack::pacemaker::params"],
                             ["heat_cfn_admin_vip", "quickstack::pacemaker::params"],
                             ["heat_cfn_private_vip", "quickstack::pacemaker::params"],
                             ["heat_cfn_public_vip", "quickstack::pacemaker::params"],
                             ["heat_private_vip", "quickstack::pacemaker::params"],
                             ["heat_public_vip", "quickstack::pacemaker::params"],
                             ["keystone_admin_vip", "quickstack::pacemaker::params"],
                             ["keystone_private_vip", "quickstack::pacemaker::params"],
                             ["keystone_public_vip", "quickstack::pacemaker::params"],
                             ["lb_backend_server_addrs", "quickstack::pacemaker::params"],
                             ["lb_backend_server_names", "quickstack::pacemaker::params"],
                             ["loadbalancer_admin_vip", "quickstack::pacemaker::params"],
                             ["loadbalancer_private_vip", "quickstack::pacemaker::params"],
                             ["loadbalancer_public_vip", "quickstack::pacemaker::params"],
                             ["neutron_admin_vip", "quickstack::pacemaker::params"],
                             ["neutron_private_vip", "quickstack::pacemaker::params"],
                             ["neutron_public_vip", "quickstack::pacemaker::params"],
                             ["nova_admin_vip", "quickstack::pacemaker::params"],
                             ["nova_private_vip", "quickstack::pacemaker::params"],
                             ["nova_public_vip", "quickstack::pacemaker::params"],
                             ["private_iface", "quickstack::pacemaker::params"],
                             ["private_ip", "quickstack::pacemaker::params"],
                             ["qpid_vip", "quickstack::pacemaker::params"],
                             ["swift_admin_vip", "quickstack::pacemaker::params"],
                             ["swift_private_vip", "quickstack::pacemaker::params"],
                             ["swift_public_vip", "quickstack::pacemaker::params"]]
    }

    def ui_params_for_form(hostgroup = self.hostgroups.first)
      return [] if (hostgroup.nil?)
      if hostgroup.puppetclasses.blank?
        params_from_hash = []
      else
        puppetclass = hostgroup.puppetclasses.first
        params_from_hash = UI_PARAMS.fetch(self.name,[]).collect do |param_key|
          if param_key.is_a?(Array)
            param_name = param_key[0]
            param_puppetclass = Puppetclass.find_by_name(param_key[1])
          else
            param_name = param_key
            param_puppetclass = puppetclass
          end
          param_lookup_key = param_puppetclass.class_params.where(:key=>param_key).first
          param_lookup_key.nil? ? nil : {:hostgroup => hostgroup,
                                         :puppetclass => param_puppetclass,
                                         :param_key => param_lookup_key}
        end.compact
      end
      params_from_hash
    end
  end
end
