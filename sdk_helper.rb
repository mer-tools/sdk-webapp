require "sinatra/base"
require "sass"

class SdkHelper < Sinatra::Base
  
  use Rack::MethodOverride #this is needed for delete methods

  get "/index.css" do
    sass :index
  end

  ######## default routes ########
  get '/' do
    @toolchain_list = toolchain_list()
    @default_target = target_show_default()
    @targets = target_list()
    @sdk_version = sdk_version()
    haml :index
  end

  #install toolchain
  post '/toolchain/:toolchain' do
    toolchain = params[:toolchain]
    toolchain_install(toolchain)
    redirect to('/')
  end

  #remove toolchain - not supported at the moment by sdk
  delete '/toolchain/:toolchain' do
    toolchain = params[:toolchain]
    toolchain_remove(toolchain)
    redirect to('/')
  end

  #add target
  post '/target/add' do
    @target_name = params[:target_name]
    @target_url = params[:target_url]
    @target_toolchain = params[:target_toolchain]
    target_add(@target_name, @target_url, @target_toolchain)
    redirect to('/')
  end
  
  #remove target
  delete '/target/:target' do
    target = params[:target] if params[:target]
    ret = target_remove(target)
    redirect to('/')
  end

  #set default target
  post '/target/:target' do
    default = params[:target] if params[:target]
    ret = target_set_default(default)
    redirect to('/')
  end

  #upgrade target
  post '/target/:target/upgrade' do
    target = params[:target] if params[:target]
    target_upgrade(target)
    redirect to('/')
  end

  #upgrade sdk
  post '/sdk/' do
    sdk_upgrade()
    redirect to('/')
  end
  ####### helper functions #######
  helpers do
    def toolchain_list()
      list = `sdk-manage --toolchain --list`.split.map {|line| line.split(',')  }.map { |tc, i| [tc, i == 'i'] }
      return list
    end

    def toolchain_install(name)
      ret = `sdk-manage --toolchain --install #{name}`
    end

    def toolchain_remove(name)
      `sdk-manage --toolchain --remove #{name}`
    end

    def target_list()
      return `sdk-manage --target --list`.split
    end

    def target_show_default()
      return `sb2-config showtarget`.strip()
    end

    def target_add(name, url, toolchain)
      ret = `sdk-manage --target --install #{name} #{toolchain} #{url}`
    end

    def target_remove(name)
      ret = `sdk-manage --target  --remove #{name}`
    end

    def target_set_default(name)
      `sb2-config -d #{name}`
    end

    def target_upgrade(target)
      # `sdk-manage --target --name #{target} --upgrade`
    end

    def sdk_version()
      `sdk-manage --sdk --version`.split("\n")
    end
    
    def sdk_upgrade()
      `sdk-manage --sdk --upgrade`
    end
  end
end
