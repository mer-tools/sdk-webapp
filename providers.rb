require 'json'

class Provider
  include Enumerable
  attr_accessor :name, :url

  def id
    return @id
  end

  def initialize(name, url)
    @name = name
    @url = url
    @@providers ||= Array.new
    @@providers << self
    @id = @@providers.length-1
  end

  def delete()
    @@providers.delete(@id)
  end

  def to_json(*a)
    {
      "json_class"   => self.class.name,
      "data"         => {"name" => @name, "url" => @url }
    }.to_json(*a)
  end
 
  def self.json_create(o)
    new(o["data"]["name"], o["data"]["url"])
  end

  # Some class methods to handle iteration and save/load
  def self.each
    for e in @@providers do
      yield e
    end
  end

  def self.delete(id)
    @@providers.delete_at(id.to_i)
  end

  def self.load
    return if @@providers
    @@providers = []
    begin
      File.open("/etc/mersdk/providers.json","r") do |f|
        list = JSON.parse(f.read)
      end
    rescue # if there's no file we have no providers
    end
  end

  def self.save
    File.open("/etc/mersdk/providers.json","w") do |f|
      f.write(JSON.pretty_generate(@@providers))
    end
  end

end
  
