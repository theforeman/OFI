module Staypuft
  class VipNic < Nic::Managed
    has_one :deployment_vip_nic, :dependent => :destroy, :class_name => 'Staypuft::DeploymentVipNic'
    has_one :deployment, :class_name => 'Staypuft::Deployment', :through => :deployment_vip_nic

    before_save   :reserve_ip
    before_destroy :release_ip

    # VIP nic is associated with the deployment, not the host
    def require_host?
      false
    end

    def reserve_ip
      # if changing subnets from dhcp network, clear old reservation
      if self.subnet_id_changed? && self.subnet_id_was
        old_subnet = Subnet.find(self.subnet_id_was)
        if old_subnet && (old_subnet.ipam == Subnet::IPAM_MODES[:dhcp]) && old_subnet.dhcp?
          begin
            old_subnet.dhcp_proxy.delete(old_subnet.network, self.mac)
          rescue ProxyAPI::ProxyException => ex
            Rails.logger.error "Error removing DHCP address reservation for VIP nic #{identifier}_#{mac.delete(':')}, mac #{mac}: #{ex}"
          end
        end
      end
      if self.subnet.present? && self.subnet.ipam? && (!self.ip || self.subnet_id_changed?)
        self.ip = self.subnet.unused_ip
        if (subnet.ipam == Subnet::IPAM_MODES[:dhcp]) && subnet.dhcp?
          begin
            subnet.dhcp_proxy.set(subnet.network, {:mac => self.mac, :ip => self.ip, :hostname => "#{identifier}_#{mac.delete(':')}"})
          rescue ProxyAPI::ProxyException => ex
            Rails.logger.error "Error reserving DHCP address for VIP nic #{identifier}_#{mac.delete(':')}, mac #{mac}: #{ex}"
          end
        end
      end
    end

    def release_ip
      # if changing subnets from dhcp network, clear old reservation
      if subnet.present? && (subnet.ipam == Subnet::IPAM_MODES[:dhcp]) && subnet.dhcp?
        begin
          subnet.dhcp_proxy.delete(subnet.network, self.mac)
        rescue ProxyAPI::ProxyException => ex
          Rails.logger.error "Error removing DHCP address reservation for VIP nic #{identifier}_#{mac.delete(':')}, mac #{mac}: #{ex}"
        end
      end
    end
  end
end
