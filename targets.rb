require 'json'
require './process.rb'

# A Target is simply a name to allow target operations
# All data is stored in the target install in sb2
# Refreshing is carried out by a systemd timer
class Target
  include Enumerable
  attr_accessor :name, :url, :toolchain
  @@all_targets=[]
  @@targets=[]
  UPDATE_VALID_PERIOD=7200

  def id
    return @id
  end

  def initialize(name)
    @name = name
    @last_update_check=Time.at(0)
    @@targets << self
    @id = @@targets.size - 1
  end

  # Installs a target to the filesystem and sb2 using a url/toolchain pair
  def create(url, toolchain)
    CCProcess.start("sdk-manage --target --install '#{@name}' '#{toolchain}' '#{url}'", (_ :adding_target) + " #{@name}", 60*60)
  end

  # Removes a target from the fs and sb2
  def remove()
    CCProcess.start("sdk-manage --target --remove '#{@name}'", (_ :removing_target) + " #{@name}", 60*15)
    @@targets.delete(@name)
  end

  # Is the target in targets.xml and known to the SDK?
  def is_known
    TargetsXML.has_target(@name)
  end

  # Is there an sb2 target setup already?
  def exists
    self.class.exists(@name)
  end

  # Is the cache out of date?
  def _update_check_needed
    (Time.now - @last_update_check) > UPDATE_VALID_PERIOD
  end

  # Force check what updates are available
  def _check_for_updates
    @update_info = CCProcess.complete("sdk-manage --target --upgradable '#{@name}'")
    @last_update_check = Time.now
  rescue CCProcess::Failed
    ""
  end

  def update_info
    if _update_check_needed then
      _check_for_updates
    end
    return @update_info
  end

  # Are any updates available
  def update_available?()
    update_info != ""
  end

  def update()
    CCProcess.start("sdk-manage --target --update '#{@name}'", (_ :syncing_target) + " #{@name}", 60*15)
  end

  def version
    _ :version_not_available
  end

  def sync()
    CCProcess.start("sdk-manage --target --sync '#{@name}'", (_ :syncing_target) + " #{@name}", 60*15)
  end

  def refresh()
    CCProcess.start("sdk-manage --target --refresh '#{@name}'", (_ :refreshing_target) + " #{@name}", 60*15)
    end
  
  # Some class methods to handle iteration and save/load

  def self.load
    @@all_targets = CCProcess.complete("sdk-manage --target --list").split.map{ |n| self.get(n) }
    @@targets = @@all_targets.keep_if {|t| t.is_known }
  rescue CCProcess::Failed
    @@targets = []
  end

  def self.get(name)
    i = @@targets.index {|t| t.name == name }
    if i == nil then
      new(name)
    else
      t=@@targets[i]
      @@targets[i]
    end
  end

  def self.exists(name)
    @@all_targets.index {|t| t.name == name } != nil
  end

  def targets_available_update
    @targets_available = []
    $server_list.each do |url|
      begin
        response = RestClient::Request.execute(method: :get, url: url, timeout: 10, open_timeout: 10)
        response = response.split(/\r?\n/).select { |line| 
          line[0] != "#" and line[0..1] != "//"
        }.join("\n")
        targets = JSON.parse(response)
        targets.each do |target|
          if ! @targets_list.include? target["name"] 
            @targets_available.push(target)
          end
        end
      rescue
      end
    end
  end
    
  def self.update_check_needed
    needed=false
    Target.each { |t| needed &&= t._update_check_needed }
    return needed
  end

  def self.check_for_updates
    Target.each do |t|
      t.check_for_updates
    end
  end

  def self.each
    for t in @@targets do
      yield t
    end
  end

  def self.all
    @@targets
  end

  def self.delete(id)
    @@targets.delete_at(id.to_i)
  end

end

require 'rexml/document'
class TargetsXML
  TARGETS_XML="/host_targets/targets.xml"
  @@xml_mtime = Time.at(0)

  def self.targets
    if ! File.exists?(TARGETS_XML) then
      return @@targets=[]
    end
    if File.mtime(TARGETS_XML) > @@xml_mtime then
      @@targets = @@doc = nil
    end

    if ! @@targets then
      doc = REXML::Document.new File.new TARGETS_XML
      @@xml_mtime = File.mtime(TARGETS_XML)
      @@targets = []
      doc.elements.each('targets/target') { |ele|
        @@targets << ele.attributes["name"]
      }
    end
    @@targets
  end

  def self.has_target(name)    
    return targets.include? name 
  end
end
