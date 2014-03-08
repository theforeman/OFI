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
  module Host
    class Create < Dynflow::Action

      def plan(name, hostgroup, compute_resource)
        # TODO set action_subject
        compute_attributes = hostgroup.
            compute_profile.
            compute_attributes.
            where(compute_resource_id: compute_resource.id).
            first.
            vm_attrs

        plan_self name:                name,
                  hostgroup_id:        hostgroup.id,
                  compute_resource_id: compute_resource.id,
                  compute_attributes:  compute_attributes
      end

      def run
        #noinspection RubyArgCount
        api = ApipieBindings::API.new uri:      'https://foreman.example.com/',
                                      username: 'admin',
                                      password: 'changeme' # FIXME use Oauth
        api.resource(:hosts).
            action(:create).
            call(host: { name:                input[:name],
                         hostgroup_id:        input[:hostgroup_id],
                         compute_resource_id: input[:compute_resource_id],
                         compute_attributes:  input[:compute_attributes] })
        # TODO suspend and wait for the provisioning to finish
      end

    end
  end
end
