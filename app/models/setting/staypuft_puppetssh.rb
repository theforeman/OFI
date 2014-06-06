class Setting::StaypuftPuppetssh < ::Setting
  BLANK_ATTRS << "dynflow_sshkey"

  def self.load_defaults
    # Check the table exists
    return unless super
    s = self.set("dynflow_sshkey",
                 _("Path to the SSH Key used by DynFlow tasks to test SSH configuration on host machines"),
                 '/usr/share/foreman/.ssh/proxy_rsa')
    self.create s.update(:category => "Setting::StaypuftProvisioning")
    true
  end

end
