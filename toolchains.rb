require 'json'
require './process.rb'

# Toolchains are managed by sdk-manage --toolchain
# The class provides a cached list of objects via class.each() and class.get(name)

class Toolchain
  include Enumerable
  attr_accessor :name, :installed
  @@toolchains={}
  UPDATE_VALID_PERIOD=7200
  @@last_update_check=Time.at(0)

  def initialize(name, installed)
    @name = name
    @installed = installed
  end

  # Installs a toolchain to the filesystem
  def install()
    if ! @installed
      puts "sdk-manage --toolchain --install '#{@name}'"
      CCProcess.start("sdk-manage --toolchain --install '#{@name}'", (_ :adding_toolchain) + " #{@name}", 60*60)
    end
  end

  # Cached information from sdk-manage
  def self._toolchains()
    if (Time.now - @@last_update_check) > UPDATE_VALID_PERIOD then
      @@toolchains = {}
      CCProcess.complete("sdk-manage --toolchain --list").split.map {|line| line.split(',')  }.map { |tc, i| @@toolchains[tc] = Toolchain.new(tc, (i == 'i')) }
    end
    @@toolchains
  rescue CCProcess::Failed
    @@toolchains = {} #FIXME: nil if can't read the list!
  end

  def self.get(name)
    _toolchains[name]
  end

  def self.exists(name)
    get(name) != nil
  end

  def self.each
    for name, obj in _toolchains do
      yield obj
    end
  end

end
