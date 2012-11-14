class SdkHelper < Sinatra::Base

  use Rack::MethodOverride #this is needed for delete methods

  get "/index.css" do
    sass :index
  end

  ######## default routes ########
  get '/' do
    list = toolchain_list()
    if list.count == 1 #zypper is locked
      @toolchain_list = $toolchainlist_cached
    else
      @toolchain_list = list
      $toolchainlist_cached = list
    end
    @default_target = target_show_default()
    @targets = target_list()
    @sdk_version = sdk_version()
    out = process_output()
    if out
      @auto_refresh = true
      splited = out.split("\n")
      @status_out = (splited[(-[10,splited.size].min)..-1] or []).join("<br/>")
    end
    haml :index
  end
  
  get '/toolchain/' do
    list = toolchain_list()
    if list.count == 1 #zypper is locked
      @toolchain_list = $toolchainlist_cached
    else
      @toolchain_list = list
      $toolchainlist_cached = list
    end
    out = process_output()
    if out
      @auto_refresh = true
      splited = out.split("\n")
      @status_out = (splited[(-[10,splited.size].min)..-1] or []).join("<br/>")
    end
    haml :toolchain
  end

  get '/target/' do
    list = toolchain_list()
    if list.count == 1 #zypper is locked
      @toolchain_list = $toolchainlist_cached
    else
      @toolchain_list = list
      $toolchainlist_cached = list
    end

    @default_target = target_show_default()
    @targets = target_list()
    out = process_output()
    if out
      @auto_refresh = true
      splited = out.split("\n")
      @status_out = (splited[(-[10,splited.size].min)..-1] or []).join("<br/>")
    end
    haml :targets
  end

  #install toolchain
  post '/toolchain/:toolchain' do
    toolchain = params[:toolchain]
    toolchain_install(toolchain)
    redirect to('/toolchain/')
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
    redirect to('/target/')
  end
 
  #remove target
  delete '/target/:target' do
    target = params[:target] if params[:target]
    ret = target_remove(target)
    redirect to('/target/')
  end

  #set default target
  post '/target/:target' do
    default = params[:target] if params[:target]
    ret = target_set_default(default)
    redirect to('/target/')
    end

  #upgrade target
  post '/target/:target/upgrade' do
    target = params[:target] if params[:target]
    target_upgrade(target)
    redirect to('/target/')
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
      if not $process
        $process_output = ""
        $process = open("| sdk-manage --toolchain --install #{name}")
      end
    end

    def process_output()
      begin
        @refresh_time = "3"
        if not $process
          nil
        else
          $process_output += $process.read_nonblock(2000000)
        end
      rescue EOFError
        @auto_refresh = false
        $process = nil
        nil
      rescue Errno::EAGAIN
        return $process_output
      end
    end

    def toolchain_remove(name)
      if not $process
        $process_output = ""
        $process = open("|sdk-manage --toolchain --remove #{name}")
      end
    end

    def target_list()
      return `sdk-manage --target --list`.split
    end

    def target_show_default()
      return `sb2-config showtarget`.strip()
    end

    def target_add(name, url, toolchain)
      if not $process
        $process_output = ""
        $process = open("|sdk-manage --target --install #{name} #{toolchain} #{url}")
      end
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
      if not $process
        $process_output = ""
        $process = open("|sdk-manage --sdk --upgrade")
      end
    end
    
  end
end
