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

        def plan(hostgroups, hosts_to_deploy_filter, hosts_to_provision_filter)
          hosts_to_deploy_filter ||= hostgroups.
              map(&:hosts).
              reduce(&:+).
              select { |h| !h.open_stack_deployed? }

          hosts_to_provision_filter ||= hosts_to_deploy_filter.select(&:managed?)

          (Type! hostgroups, Array).all? { |v| Type! v, ::Hostgroup }
          (Type! hosts_to_deploy_filter, Array).all? { |v| Type! v, ::Host::Base }

          sequence do
            hosts              = hostgroups.map(&:hosts).reduce(&:+)
            hosts_to_provision = hosts & hosts_to_provision_filter
            hosts_to_deploy    = hosts & hosts_to_deploy_filter
            hosts_to_provision.each { |host| plan_action Host::TriggerProvisioning, host }

            concurrence do
              hosts_to_provision.each { |host| plan_action Host::WaitUntilProvisioned, host }
            end

            input.update hostgroups: {}
            hostgroups.each do |hostgroup|
              concurrence do
                input[:hostgroups].update hostgroup.id => { name: hostgroup.name, hosts: {} }

                (hostgroup.hosts & hosts_to_deploy_filter).each do |host|
                  input[:hostgroups][hostgroup.id][:hosts].update host.id => host.name

                  sequence do
                    plan_action Host::WaitUntilReady, host
                    plan_action Host::Deploy, host
                  end
                end
              end
            end

            enable_puppet_agent hosts_to_deploy
          end
        end

        def enable_puppet_agent(hosts)
          lookup_key_runmode_id = Puppetclass.
              find_by_name('foreman::puppet::agent::service').
              class_params.
              where(key: 'runmode').
              first.
              tap { |v| v || raise('missing runmode LookupKey') }.
              id

          concurrence do
            hosts.each do |host|
              # enable puppet agent
              plan_action(Actions::Staypuft::Host::Update, host,
                          lookup_values_attributes:
                              { nil => { lookup_key_id: lookup_key_runmode_id,
                                         value:         'service' } })

            end
          end

          puppet_runs = sequence do
            hosts.map do |host|
              plan_action Actions::Staypuft::Host::PuppetRun, host
            end
          end

          concurrence do
            hosts.zip(puppet_runs).each do |host, puppet_run|
              plan_action Actions::Staypuft::Host::ReportCheck, host.id, puppet_run.output[:executed_at]
            end
          end
        end

        def humanized_input
          planned_actions.map(&:humanized_input).join(', ')
        end

        def humanized_output
	  ""
        end

        def task_output
          {}
        end
      end
    end
  end
end
