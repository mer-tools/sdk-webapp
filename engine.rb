require 'json'

# A Engine is simply a name to allow engine operations
# All data is stored in the engine install
#
class Engine
  # What updates are available
  def self.update_available
    process_complete("sdk-manage --engine --status '#{@name}'")
  end

  # Are any updates available
  def self.update_available?
    true
  end

  def self.update
    process_start("sdk-manage --sdk --update", (_ :updating_engine) + " #{@name}", 60*15)
  end

  def self.load
  end
end
