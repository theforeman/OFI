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
    module Hostgroup
      # deploys Hostgroups in given order
      class OrderedDeploy < Actions::Base

        middleware.use Actions::Staypuft::Middleware::AsCurrentUser

        def plan(hostgroups, hosts_to_deploy, hosts_to_provision)
          hosts_to_deploy    = hostgroups.map(&:hosts).reduce(&:+) if hosts_to_deploy.nil?
          hosts_to_provision = hosts_to_deploy.select(&:managed?) if hosts_to_provision.nil?

          (Type! hostgroups, Array).all? { |v| Type! v, ::Hostgroup }
          (Type! hosts_to_deploy, Array).all? { |v| Type! v, ::Host::Base }


          sequence do
            hosts = hostgroups.map(&:hosts).reduce(&:+) & hosts_to_provision
            hosts.each { |host| plan_action Host::TriggerProvisioning, host }

            concurrence do
              hosts.each { |host| plan_action Host::WaitUntilProvisioned, host }
            end

            input.update hostgroups: {}
            hostgroups.each do |hostgroup|
              concurrence do
                input[:hostgroups].update hostgroup.id => { name: hostgroup.name, hosts: {} }

                (hostgroup.hosts & hosts_to_deploy).each do |host|
                  input[:hostgroups][hostgroup.id][:hosts].update host.id => host.name

                  sequence do
                    plan_action Host::WaitUntilReady, host
                    plan_action Host::Deploy, host
                  end
                end
              end
            end
          end
        end

        def humanized_input
          planned_actions.map(&:humanized_input).join(', ')
        end

        def humanized_output
          steps          = all_planned_actions.map { |a| a.steps[1..2] }.reduce(&:+).compact
          stets_by_hosts = steps.inject({}) do |hash, step|
            key       = step.action(execution_plan).input[:host_id]
            hash[key] ||= []
            hash[key] << step
            hash
          end

          progresses_by_host = stets_by_hosts.inject({}) do |hash, (host_id, steps)|
            progress = if steps.empty?
                         'done'
                       else
                         total          = steps.map { |s| s.progress_done * s.progress_weight }.reduce(&:+)
                         weighted_count = steps.map(&:progress_weight).reduce(&:+)
                         format '%3d%%', total / weighted_count * 100
                       end

            hash.update host_id => progress
          end

          input.fetch(:hostgroups).map do |_, hostgroup|
            [hostgroup[:name],
             *hostgroup[:hosts].map { |id, name| format '  %s Host: %s', progresses_by_host[id.to_i], name },
             ('    -' if hostgroup[:hosts].empty?)
            ].compact
          end.join("\n")
        end
      end
    end
  end
end
