module Vagrant
  module Action

    class Up
      def initialize(app, env)
        @app = app
        @machine = env[:machine]
        @zone = env[:machine].config.powerdns.default_zone
        @host = env[:machine].config.vm.hostname.nil? ?
          env[:machine].name.to_s : env[:machine].config.vm.hostname.to_s
        @domain = @host.include?(@zone.name)? @host : @host + @zone.dotted

        # Identify who i am
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
              zone = @zone.name

              p = PdnsRestApiClient.new(env[:machine].config.powerdns.api_url,
                                        env[:machine].config.powerdns.api_key)

              # Only update if IP changed or inactive
              record_not_found = p.zone(zone)["records"].select {|v| v["type"] == "A" and v["name"] == @domain and v["content"] == ip}.empty?
              record_disabled = p.zone(zone)["records"].select { |v| v["type"] == "A" and v["name"] == @domain and v["disable"]}.empty?

              if record_not_found or record_disabled
                env[:ui].info "PowerDNS action..."
                # Append new comment
                new_comment = {
                  content: "#{@myuser} added this record from #{@myhost}",
                  account: @myuser,
                  name: @domain,
                  type: "A"
                }
                comments = p.zone(zone)["comments"].delete_if { |v| v["name"] != @domain  }
                comments << new_comment

                ret = p.modify_domain(domain: @domain, ip: ip, zone_id: zone,
                                      comments: comments)

                # Check return
                error = nil
                if ret.is_a?(String)
                  error = ret
                else
                  if ret.is_a?(Hash)
                    error = ret.values[0] if ret.keys[0] == "error"
                  else
                    raise "Unknown esponse from PowerDNS API"
                  end
                end

                # Display ui
                if error.nil?
                    env[:ui].detail "=> record #{@domain}(#{ip}) in zone #{zone} added !"
                else
                  env[:ui].detail "=> failed to add record #{@domain}(#{ip}) in zone #{zone}. Error was: #{error}"
                end
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
        @zone = env[:machine].config.powerdns.default_zone
        @host = env[:machine].config.vm.hostname.nil? ?
          env[:machine].name.to_s : env[:machine].config.vm.hostname.to_s
        @domain = @host.include?(@zone.name)? @host : @host + @zone.dotted

        # Identify who i am
        @myuser = Etc.getlogin.gsub(/\s+/, '')
        @myhost = Socket.gethostname
      end

      def call(env)
        if @machine.config.powerdns.enabled?
          p = PdnsRestApiClient.new(env[:machine].config.powerdns.api_url,
                                    env[:machine].config.powerdns.api_key)

          zone = @zone.name
          # Get A record
          record = p.zone(zone)["records"].find {|v| v["name"] == @domain}

          # only disable if active
          if !record.nil? and not record["disabled"]
            env[:ui].info "PowerDNS action..."

            # Prepare comment to be appended
            new_comment = {
              content: "#{@myuser} disabled this record from #{@myhost}",
              account: @myuser,
              name: @domain,
              type: "A"
            }
            comments = record["comments"].delete_if { |v| v["name"] != @domain }
            comments << new_comment

            # Get the old IP
            ip = record["records"].find {|v| v["name"] == @domain}["content"]

            ret = p.disable_domain(domain: @domain, ip: ip, zone_id: zone,
                                   comments: comments)

            # Check return
            error = nil
            if ret.is_a?(String)
              error = ret
            else
              if ret.is_a?(Hash)
                error = ret.values[0] if ret.keys[0] == "error"
              else
                raise "Unknown esponse from PowerDNS API"
              end
            end

            # Display ui
            if error.nil?
                env[:ui].detail "=> record #{@domain}(#{ip}) in zone #{zone} disabled !"
            else
              env[:ui].detail "=> failed to disab;e record #{@domain} in zone #{zone}. Error was: #{error}"
            end
          end

          @app.call(env)
        end
      end
    end

  end
end