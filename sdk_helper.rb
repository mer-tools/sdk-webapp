require "sinatra/base"
require "sass"

class SdkHelper < Sinatra::Base
  use Rack::MethodOverride


  get "/index.css" do
    sass :index
  end
 
  ######## default routes ########
  get '/' do

    @links = %w{target_add}.map 
    @toolchain_list = toolchain_list()
    @default_target = target_show_default()
    # @targets = target_list().split
    @targets = target_list()
    haml :index
  end
  
  post '/toolchain/:toolchain' do
    toolchain = params[:toolchain]
    "installing toolchain #{toolchain}"
  end

  delete '/toolchain/:toolchain' do
    toolchain = params[:toolchain]
    "removing toolchain: #{toolchain}"
  end
  
  post '/target/add' do
    @target_name = params[:target_name]
    @target_url = params[:target_url]
    target_add(@target_name, @target_url)
    redirect to('/')
  end
  
  delete '/target/:target' do
    target = params[:target] if params[:target]
    ret = target_remove(target)
    redirect to('/')
  end

  post '/target/:target' do
    default = params[:target] if params[:target]
    ret = target_set_default(default)
    redirect to('/')
  end

  post '/target/:target/upgrade' do
    target = params[:target] if params[:target]
    target_upgrade(target)
    redirect to('/')
  end
  
  ####### helper functions #######
  helpers do
    def toolchain_list()
      # `sb2_manage --toolchain --list`
      #fake list
      return [["Mer-SB2-armv6l", true], ["Mer-SB2-armv7hl", true], ["Mer-SB2-armv7l", false],  ["Mer-SB2-armv7tnhl", true]]
    end

    def toolchain_install(name)
      #`sb2_manage --toolchain --install #{name}`
    end

    def toolchain_remove(name)
      #`sb2_manage --toolchain --remove #{name}`
    end

    def target_list()
      #`sb2-config -l`
      return ["n950-rootfs", "another", "yet_another"]
    end

    def target_show_default()
      #`sb2-config showtarget`.strip()
      return "n950-rootfs"
    end

    def target_add(name, url)
      #`cd /srv/mer/targets/#{name}; sb2-init  -L "--sysroot=/" -C "--sysroot=/" -c /usr/bin/qemu-arm-dynamic -m sdk-build -n -N -t / #{name} /opt/cross/bin/armv7hl-meego-linux-gnueabi-gcc`
      # this hack is going to be replaced with
      # `sb2_manage --target #{name} --install #{url}`
      puts "DEBUG: sb2_manage --target #{name} --install #{url}"
    end

    def target_remove(name)
      #`cd ~/.scratchbox2; rm -rf #{name}`
      # `sb2_manage --target #{name} --remove`
      puts "DEBUG: sb2_manage --target #{name} --remove"
    end

    def target_set_default(name)
      #`sb2-config -d #{name}`
    end

    def target_upgrade(target)
      puts "upgrading target #{target}"
      # `sb2_mange --target --name #{target} --upgrade`
    end
  end
end
