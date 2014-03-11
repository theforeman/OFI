#
# Copyright 2014 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

module Actions
  module Staypuft
    module Host
      class WaitUntilInstalled < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser
        include Dynflow::Action::Polling

        def plan(host_id)
          plan_self host_id: host_id
        end

        def external_task
          output[:installed_at]
        end

        def done?
          !!external_task
        end

        private

        def invoke_external_task
          nil
        end

        def external_task=(external_task_data)
          output[:installed_at] = external_task_data
        end

        def poll_external_task
          time =::Host.find(input[:host_id]).installed_at
          time ? time.to_s : nil
        end

        def poll_interval
          5
        end
      end
    end
  end
end
