# Copyright (c) 2013 Matthias Kadenbach
# https://github.com/mattes/vagrant-dnsmasq

class Zone

  MATCH = /^[a-z0-9]+([\-\.]{1}[a-z0-9]+)*$/

  def initialize(name)
    @name = nil

    if name.is_a? Zone
      name = name.dotted
    end

    raise ArgumentError, "no domain name given" if name.empty?

    # parse domain name ...
    name = name.to_s
    name = name[1..-1] if name.start_with? '.'
    name = name.downcase
    raise ArgumentError, "Zone '#{name}' must match #{MATCH}" unless Zone::valid?(name)
    @name = name # without leading .
  end

  def self.valid?(name)
    if not name.empty? and Zone::MATCH.match(name.downcase) then true else false end
  end

  def dotted
    '.' + @name
  end

  def name
    @name
  end

  def to_s
    dotted
  end

end