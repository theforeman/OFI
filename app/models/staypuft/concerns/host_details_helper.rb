require 'resolv'

module Staypuft
  module Concerns
    module HostDetailsHelper
      extend ActiveSupport::Concern

      # Returns memory in GB
      def mem
        if self.facts_hash["memorytotal"]
          self.facts_hash["memorytotal"].split(" ").first.to_f / 1000
        else
          nil
        end
      end

      # Returns total number of processes
      def cpus
        self.facts_hash["processorcount"]
      end

      # Returns model
      def model_type
        self.facts_hash["hardwaremodel"]
      end

      # Returns array of NIC names
      def network_interfaces
        if self.facts_hash["interfaces"]
          self.facts_hash["interfaces"].split(",")
        else
          nil
        end
      end

      # Returns architecture
      def architectures
        if self.facts_hash["architecture"]
          self.facts_hash["architecture"].name
        else
          nil
        end
      end

      # TODO: a better fix is needed once we have explicit subnet support in staypuft
      # This is needed because host.ip doesn't always return the expected ip address
      # when the host has more than one network interface -- this ensures that the
      # provisioning network interface is the chosen one.
      def provisioning_ip
        Resolv::DNS.new(:nameserver => 'localhost').getaddress(self.fqdn).to_s
      end
    end
  end
end

class ::Host::Managed::Jail < Safemode::Jail
  allow :provisioning_ip
end
