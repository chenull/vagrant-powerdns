#   Copyright 2015 Arnoud Vermeer (https://github.com/funzoneq/powerdns-rest-api-client)
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

require 'httparty'
require 'json'

# A class to interact with the PowerDNS REST API
# https://doc.powerdns.com/md/httpapi/api_spec/
class PdnsRestApiClient
  include HTTParty
  attr_accessor :base_uri

  def initialize(base_uri, api_key)
    self.class.base_uri base_uri

    self.class.headers 'X-API-Key' => api_key

    @api_key = api_key
  end

  def servers
    self.class.get('/servers')
  end

  def server(server_id)
    self.class.get("/servers/#{server_id}")
  end

  def config(server_id)
    self.class.get("/servers/#{server_id}/config")
  end

  def setting(server_id, config_setting_name)
    self.class.get("/servers/#{server_id}/config/#{config_setting_name}")
  end

  def zones(server_id='localhost')
    self.class.get("/servers/#{server_id}/zones")
  end

  def zone(zone_id, server_id='localhost')
    self.class.get("/servers/#{server_id}/zones/#{zone_id}")
  end

  def modify_zone(zone, server_id='localhost')
    self.class.post("/servers/#{server_id}/zones", body: zone.to_json)
  end

  def create_zone(domain, nsServers=[], kind='Native', masters=[], server_id='localhost')
    zone = { name: domain, kind: kind, masters: masters, nameservers: nsServers }

    modify_zone(zone, server_id)
  end

  def delete_zone(zone_id, server_id='localhost')
    self.class.delete("/servers/#{server_id}/zones/#{zone_id}")
  end

  def notify(zone_id, server_id='localhost')
    self.class.put("/servers/#{server_id}/zones/#{zone_id}/notify")
  end

  def axfr_retrieve(zone_id, server_id='localhost')
    self.class.put("/servers/#{server_id}/zones/#{zone_id}/axfr-retrieve")
  end

  def zone_export(zone_id, server_id='localhost')
    self.class.get("/servers/#{server_id}/zones/#{zone_id}/export")
  end

  def search_log(search_term, server_id='localhost')
    self.class.get("/servers/#{server_id}/search-log", query: { q: search_term })
  end

  def stats(server_id='localhost')
    self.class.get("/servers/#{server_id}/statistics")
  end

  def get_comments(domain, zone_id, server_id='localhost')
    puts
  end

  def modify_domain(domain:, ip:, zone_id:, server_id:'localhost', comments: nil)
    #  {
    #      :rrsets => [
    #          [0] {
    #                 :name => "gundul.dev.jcamp.net",
    #                 :type => "A",
    #                 :records => [
    #                  [0] {
    #                          :name => "gundul.dev.jcamp.net",
    #                          :type => "A",
    #                           :ttl => 3600,
    #                      :disabled => false,
    #                       :content => "192.168.10.11"
    #                      }
    #                 ],
    #                 :comments => [
    #                  [0] {
    #                             :name => "gundul.dev.jcamp.net",
    #                             :type => "A",
    #                      :modified_at => 1461239952,
    #                          :account => "ayik",
    #                          :content => "NGopoE cuk..."
    #                      }
    #                 ],
    #                 :changetype => "replace"
    #              }
    #       ]
    #  }
    @body = {
      rrsets: [
        {
          name: domain,
          type: "A",
          records: [
            {
              name: domain,
              type: "A",
              ttl: 300,
              disabled: false,
              content: ip
            }
          ],
          changetype: "replace"
        }
      ]
    }
    if !comments.nil?
       @body[:rrsets][0][:comments] = comments
    end
    self.class.patch("/servers/#{server_id}/zones/#{zone_id}", body: @body.to_json)
  end

  def disable_domain(domain:, zone_id:, ip:, server_id:'localhost', comments: nil)
    @body = {
      rrsets: [
        {
          name: domain,
          type: "A",
          records: [
            {
              name: domain,
              type: "A",
              ttl: 300,
              content: ip,
              disabled: true
            }
          ],
          changetype: "replace"
        }
      ]
    }
    if !comments.nil?
       @body[:rrsets][0][:comments] = comments
    end
    self.class.patch("/servers/#{server_id}/zones/#{zone_id}", body: @body.to_json)
  end
  # def trace(server_id='localhost')
  #  self.class.get("/servers/#{server_id}/trace")
  # end

  # def zone_check(zone_id, server_id='localhost')
  #  self.class.get("/servers/#{server_id}/zones/#{zone_id}/check")
  # end
end
