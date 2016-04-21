module Vagrant
  module Action

    class Up
      def initialize(app, env)
        @app = app
        @machine = env[:machine]
        @domain = env[:machine].name.to_s + env[:machine].config.powerdns.default_zone.to_s
        @zone = env[:machine].config.powerdns.default_zone.name

        # Identify who i am
        @myname = Etc.getpwuid[:gecos]
        @myuser = Etc.getlogin.gsub(/\s+/, '')
        @myhost = Socket.gethostname
      end

      def call(env)
        if @machine.config.powerdns.enabled?
          # assume default gateway address
          @machine.communicate.sudo "ip route get to 8.8.8.8 | head -n 1" do |type,data|
            stdout = data.chomp if type == :stdout
            if !stdout.empty?
              re = /src ([0-9\.]+)/
              ip = stdout.match(re)[1]


              env[:ui].info "PowerDNS action..."
              p = PdnsRestApiClient.new(env[:machine].config.powerdns.api_url,
                                        env[:machine].config.powerdns.api_key)
              # Append new comment
              zone = @zone
              new_comment = {
                content: "#{@myname} (#{@myuser}) added this record from #{@myhost}",
                account: @myname,
                name: @domain,
                type: "A"
              }
              comments = p.zone(zone)["comments"] << new_comment

              ret = p.modify_domain(domain=domain, ip=ip, zone_id=zone, comments=comments)
              # Check return
              if ret.is_a?(Hash)
                env[:ui].detail "=> record #{domain}(#{ip}) in zone #{zone} added !"
              else
                env[:ui].detail "=> failed to add record #{domain}(#{ip}) in zone #{zone}. Error was: #{ret}"
              end
            end
          end

          @app.call(env)
        end
      end
    end


    class Destroy
      def initialize(app, env)
        @app = app
        @machine = env[:machine]
      end

      def call(env)
        if @machine.config.powerdns.enabled?
          env[:ui].info "PowerDNS destroy"

          puts "***********************************"

          @app.call(env)
        end
      end
    end

  end
end