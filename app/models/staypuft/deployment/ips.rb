
module Staypuft
  class Deployment::IPS < Deployment::AbstractParamScope

    class Jail < Safemode::Jail
      allow :controller_ip, :controller_ips, :controller_fqdns
    end

    def controllers
      @controllers ||= deployment.controller_hostgroup.hosts.order(:id)
    end

    def controller_ips
      controllers.map &:provisioning_ip
    end

    def controller_fqdns
      controllers.map &:fqdn
    end

    def controller_ip
      controllers.tap { |v| v.size == 1 or raise }.first.provisioning_ip
    end

  end
end
