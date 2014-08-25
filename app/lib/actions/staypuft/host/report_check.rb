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

      class ReportCheck < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser
        include Dynflow::Action::Polling

        def plan(host_id, after)
          plan_self host_id: host_id, after: after
        end

        def external_task
          output[:status]
        end

        def done?
          external_task
        end

        def run_progress_weight
          4
        end

        def run_progress
          0.1
        end

        private

        def invoke_external_task
          nil
        end

        def external_task=(external_task_data)
          output[:status] = external_task_data
        end

        def poll_external_task
          host_ready?(input[:host_id], DateTime.parse(input[:after]).to_time)
        end

        def poll_interval
          5
        end

        def host_ready?(host_id, after)
          host   = ::Host.find(host_id)
          report = host.reports.where('reported_at > ?', after).first
          return false unless report

          check_for_failures(report, host.id)
          report_change?(report)
        end

        def report_change?(report)
          report.status['applied'] > 0
        end

        def check_for_failures(report, id)
          if report.status['failed'] > 0
            output[:report_id] = report.id
            fail(::Staypuft::Exception, "Latest Puppet Run Contains Failures for Host: #{id}")
          end
        end

      end
    end
  end
end
