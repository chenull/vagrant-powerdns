# Vagrant PowerDNS

This Vagrant Plugins manage DNS `A` Record whenever you do `vagrant up` or `vagrant destroy`. Tested with old/compatible API of PowerDNS 4, so it should be configured with `last-3x-compat` tag

## Installation

    $ vagrant plugin install vagrant-powerdns

## Usage

Vagrantfile Example

```ruby
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "centos7"
  config.vm.hostname = "ayik"

  # PowerDNS API Configuration
  config.powerdns.api_url = "http://powerdns:8081"
  config.powerdns.api_key = "rahasia"
  config.powerdns.default_zone = "dev.example.com"

  config.vm.network "public_network", ip: "192.168.2.2"
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/chenull/vagrant-powerdns.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

