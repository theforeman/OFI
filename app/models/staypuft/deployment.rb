module Staypuft
  class Deployment < ActiveRecord::Base
    attr_accessible :description, :name, :layout_id, :layout
    after_save :update_hostgroup_name

    belongs_to :layout
    belongs_to :hostgroup, :dependent => :destroy

    has_many :deployment_role_hostgroups, :dependent => :destroy, :order => "staypuft_deployment_role_hostgroups.deploy_order ASC"

    # using custom finder_sql instead of :has_many, :through since :order on hostgroup
    # queries doesn't work (Hostgroup overrides default_scope to order by label -- this
    # can't be undone here because .except(:order) only works on queries, not in :has_many
    # and unscope doesn't work in rails 3)
    has_many :child_hostgroups, :class_name => 'Hostgroup', :source => :hostgroup, :finder_sql => Proc.new {
      %Q{
           SELECT hostgroups.* 
           FROM hostgroups 
           INNER JOIN staypuft_deployment_role_hostgroups
                 ON hostgroups.id = staypuft_deployment_role_hostgroups.hostgroup_id
           WHERE staypuft_deployment_role_hostgroups.deployment_id = #{id}
           ORDER BY staypuft_deployment_role_hostgroups.deploy_order ASC
       }
    }

    has_many :roles, :through => :deployment_role_hostgroups, :order => "staypuft_deployment_role_hostgroups.deploy_order ASC"

    validates  :name, :presence => true, :uniqueness => true

    validates :layout, :presence => true
    validates :hostgroup, :presence => true

    scoped_search :on => :name, :complete_value => :true

    def destroy
      child_hostgroups.each do |h|
        h.destroy
      end
      #do the main destroy
      super
    end

    # After setting or changing layout, update the set of child hostgroups,
    # adding groups for any roles not already represented, and removing others
    # no longer needed.
    def update_hostgroup_list
      old_role_hostgroups_arr = deployment_role_hostgroups.to_a
      layout.layout_roles.each do |layout_role|
        role_hostgroup = deployment_role_hostgroups.where(:role_id=>layout_role.role).first_or_initialize do |drh|
          drh.hostgroup = Hostgroup.nest(layout_role.role.name, hostgroup)
        end

        role_hostgroup.hostgroup.add_puppetclasses_from_resource(layout_role.role)
        role_hostgroup.hostgroup.save!

        role_hostgroup.deploy_order = layout_role.deploy_order
        role_hostgroup.save!

        old_role_hostgroups_arr.delete(role_hostgroup)
      end
      # delete any prior mappings that remain
      old_role_hostgroups_arr.each do |role_hostgroup|
        role_hostgroup.hostgroup.destroy
      end
    end

    private
    def update_hostgroup_name
      hostgroup.name = self.name
      hostgroup.save!
    end


  end
end
