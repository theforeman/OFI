module Staypuft
  class HostsController < ::HostsController

    def update
      Rails.logger.debug("*******************************")
      Rails.logger.debug("HostsController overridden! \o/")

      super
    end

  end
end
