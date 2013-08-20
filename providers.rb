require 'json'

class Provider
  include Enumerable
  @@providers = nil

  attr_accessor :name, :url, :success
  UPDATE_VALID_PERIOD=7200
  # By default we're running in /usr/lib/sdk-webapp-bundle
  PROVIDERS_JSON="config/providers.json"
  @@json_mtime = Time.at(0)

  def id
    return @id
  end

  def initialize(name, url)
    @name = name
    @url = url
    @success=false
    @targetTemplates=[]
    @last_update_check = Time.at(0)

    # Now add ourselves to the class list
    @@providers ||= [] # First instance needs an array
    @@providers << self
    @id = @@providers.length-1

    targetTemplates
  end

  # Is the cache out of date?
  def _update_check_needed
    (Time.now - @last_update_check) > UPDATE_VALID_PERIOD
  end

  def targetTemplates
    if _update_check_needed then
      begin
        response = RestClient::Request.execute(method: :get, url: url, timeout: 1, open_timeout: 2)
        # ignore comment lines
        response = response.split(/\r?\n/).select { |line| 
          line[0] != "#" and line[0..1] != "//"
        }.join("\n")
        @targetTemplates = JSON.parse(response)
        @targetTemplates.each { |t| t['provider'] = @name }
        @success=true
      rescue
        @success=false
        @targetTemplates=[]
      end
    end
    @last_update_check = Time.now
    @targetTemplates
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
    for e in providers do
      yield e
    end
  end

  def self.delete(id)
    @@providers.delete_at(id.to_i)
  end

  def self.providers
    if ! File.exists?(PROVIDERS_JSON) then
      return @@providers=[]
    end
    if File.mtime(PROVIDERS_JSON) > @@json_mtime then
      @@providers = nil # force a re-read
    end
    if ! @@providers then
      begin
        File.open(PROVIDERS_JSON,"r") do |f|
          # new instances add themselves to @@providers
          dummy = JSON.parse(f.read)
        end
        @@json_mtime = File.mtime(PROVIDERS_JSON)
      rescue
        @@providers=[]
      end
    end
    @@providers
  end

  def self.save
    File.open(PROVIDERS_JSON,"w") do |f|
      f.write(JSON.pretty_generate(@@providers))
    end
    @@json_mtime = File.mtime(PROVIDERS_JSON)
  end

  def self.targetTemplates
    t=[]
    providers.each { |p| t += p.targetTemplates }
    t
  end

end
  
