require "vagrant"

module Vagrant
  module PowerDNS
    module Errors
      class PowerDNSError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_powerdns.errors")
      end

      class APIError < PowerDNSError
        error_key(:api_error)
      end

    end
  end
end

