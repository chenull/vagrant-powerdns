module Vagrant
  module PowerDNS
    class Config < Vagrant.plugin("2", :config)

      attr_accessor :api_url
      attr_accessor :api_key
      attr_accessor :default_zone
      attr_accessor :disable

      def initialize
        @api_url = UNSET_VALUE
        @api_key = UNSET_VALUE
        @default_zone = UNSET_VALUE
        @disable = UNSET_VALUE
      end

      def finalize!

        if @default_zone == UNSET_VALUE
          @default_zone = nil
        elsif !@default_zone.is_a?(Zone)
          @default_zone = Zone.new @default_zone;
        end

        @disable = false if @disable == UNSET_VALUE

        # default way to obtain ip address
        if @ip == UNSET_VALUE
          @ip = proc do |guest_machine|
            ips = nil
            puts "SUDO SUUUUUU............"
            guest_machine.communicate.sudo("hostname -I") do |type, data|
              ips = data.scan /[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/
            end
            ips
          end
        end

      end

      def enabled?
        not @disable and not @api_url.nil? and not @api_key.nil?
      end

      def validate(machine)
        return unless enabled?

        errors = []

        # verify @disable
        if @disable != true and @disable != false then errors << 'invalid disable setting' end

        # verify zone
        begin @default_zone = Zone.new @default_zone; rescue => e; errors << e.message end

        # verify ip
        if @ip.is_a? Array
          @ip.map!{|ip| begin Ip.new(ip); rescue => e; errors << e.message end}

        elsif @ip.is_a? String
          begin @ip = Ip.new(@ip); rescue => e; errors << e.message end
          @ip = [@ip]

        elsif @ip.is_a? Proc
          # okay, there is nothing to verify at the moment
        else
          @ip = nil
        end

        # verify API URL/key
        #if @resolver
        # errors << "file '#{@dnsmasqconf}' does not exist" unless File.exists? @dnsmasqconf
        #end

        return { 'PowerDNS configuration' => errors }
      end

    end
  end
end
