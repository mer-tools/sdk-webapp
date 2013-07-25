require 'json'

# A Engine is simply a name to allow engine operations
# All data is stored in the engine install
#
class Engine

  UPDATE_VALID_PERIOD=7200
  @@last_update_check=Time.at(0)

  # Is the cache out of date?
  def self._update_check_needed
    (Time.now - @@last_update_check) > UPDATE_VALID_PERIOD
  end

  # Force check what updates are available
  def self._check_for_updates
    @@update_info = CCProcess.complete("sdk-manage --sdk --upgradable")
    @@last_update_check = Time.now
  rescue CCProcess::Failed
    @@update_info=""
  end

  def self.update_info
    if _update_check_needed then
      _check_for_updates
    end
    return @@update_info
  end

  # Are any updates available
  def self.update_available?
    update_info != ""
  end

  def self.version
    _ :version_not_available
  end

  def self.update
    CCProcess.start("sdk-manage --sdk --upgrade", (_ :updating_engine) + " #{@name}", 60*15)
    @@last_update_check=Time.at(0)
  end

  def self.load
  end
end
