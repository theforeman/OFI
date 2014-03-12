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

      # creates and provisions Host waiting until it's ready
      class Provision < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(name, hostgroup, compute_resource)
          Type! hostgroup, Hostgroup
          Type! compute_resource, ComputeResource

          input[:name] = name

          sequence do
            creation = plan_action Host::Create, name, hostgroup, compute_resource
            plan_action Host::WaitUntilInstalled, creation.output[:host][:id]
            # TODO: wait until restarted
          end
        end

        def humanized_input
          input[:name]
        end

        def task_output
          planned_actions(Host::Create).first.output
        end

        def humanized_output
          task_output.fetch(:host, {})[:name]
        end
      end
    end
  end
end
