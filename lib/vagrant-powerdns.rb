begin
  require "vagrant"
rescue LoadError
  raise "The Vagrant-PowerDNS plugin must be run within Vagrant."
end


module Vagrant
  module PowerDNS
    class Plugin < Vagrant.plugin("2")
      name "vagrant-powerdns"
      description "A PowerDNS Vagrant plugin that manages the zone record via vagrant up/destroy"

      inc_path = Pathname.new(File.expand_path("../vagrant-powerdns/includes", __FILE__))
      require inc_path.join("Zone.class.rb")
      require inc_path.join("Ip.class.rb")

      util_path = Pathname.new(File.expand_path("../vagrant-powerdns/util", __FILE__))
      require util_path.join("pdns_api")

      lib_path = Pathname.new(File.expand_path("../vagrant-powerdns", __FILE__))
      require lib_path.join("action")

      config "powerdns" do
        require lib_path.join("config")
        Config
      end

      action_hook(:powerdns, :machine_action_up) do |hook|
        hook.append(Vagrant::Action::Up)
      end

      action_hook(:powerdns, :machine_action_destroy) do |hook|
        hook.append(Vagrant::Action::Destroy)
      end

      autoload :Errors, lib_path.join("errors")

      source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
      I18n.load_path << File.expand_path('locales/en.yml',  source_root)
      I18n.reload!
    end
  end

end