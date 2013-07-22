require 'json'

# A Target is simply a name to allow target operations
# All data is stored in the target install in sb2
#
class Target
  include Enumerable
  attr_accessor :name, :url, :toolchain
  @@targets=nil

  def id
    return @id
  end

  def initialize(name)
    @name = name
  end

  # Installs a target to the filesystem and sb2 using a url/toolchain pair
  def create(url, toolchain)
    process_start("sdk-manage --target --install '#{@name}' '#{toolchain}' '#{url}'", (_ :adding_target) + " #{@name}", 60*60)
  end

  # Removes a target from the fs and sb2
  def remove()
    process_start("sdk-manage --target --remove '#{@name}'", (_ :removing_target) + " #{@name}", 60*15)
    @@targets.delete(@name)
  end

  # What updates are available
  def update_available()
    process_complete("sdk-manage --target --status '#{@name}'")
  end

  # Are any updates available
  def update_available?()
    process_complete("sdk-manage --target --status '#{@name}'")
  end

  def update(target)
    process_start("sdk-manage --target --update '#{@name}'", (_ :syncing_target) + " #{@name}", 60*15)
  end

  def sync()
    process_start("sdk-manage --target --sync '#{@name}'", (_ :syncing_target) + " #{@name}", 60*15)
  end

  def refresh()
    process_start("sdk-manage --target --refresh '#{@name}'", (_ :refreshing_target) + " #{@name}", 60*15)
    end
  
  # -------------------------------- Target

  def self.load
    @@targets = process_complete("sdk-manage --target --list").split.map{ |n| Target.new(n) }
  rescue ProcessFailed
    @@targets = []
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
    

  # Some class methods to handle iteration and save/load
  def self.each
    for t in @@targets do
      yield t
    end
  end

  def self.delete(id)
    @@targets.delete_at(id.to_i)
  end

end
  
