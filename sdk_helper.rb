require './shell_process'
require_relative 'target_servers'

I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
I18n::Backend::Simple.send(:include, I18n::Backend::TS)
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.default_locale = 'en'
I18n.load_path << Dir[ "./i18n/*.ts" ]
I18n.locale = 'en'

class ProcessFailed < Exception; end

class SdkHelper < Sinatra::Base

  use Rack::MethodOverride #this is needed for delete methods

  get "/index.css" do
    sass :index
  end


  get '/' do redirect to "/"+system_language+"/targets/"; end
  get '/toolchains/' do redirect to "/"+system_language+"/toolchains/"; end
  get '/targets/' do redirect to "/"+system_language+"/targets/"; end


  get '/:locale/' do
    locale_set
    process_tail_update
    sdk_version_update
    haml :index, :locals => { :tab => :sdk }
  end
  
  get '/:locale/toolchains/' do
    locale_set
    process_tail_update
    toolchain_list_update
    haml :toolchains, :locals => { :tab => :toolchains }
  end

  get '/:locale/targets/' do
    locale_set
    process_tail_update
    toolchain_list_update
    target_default_update
    targets_list_update
    targets_available_update
    haml :targets, :locals => { :tab => :targets }
  end

  get '/:locale/targets/:target' do
    target = params[:target]
    locale_set
    process_tail_update
    packages_list_update
    haml :packages, :locals => { :tab => :targets }
  end

  #install toolchain
  post '/:locale/toolchains/:toolchain' do
    toolchain = params[:toolchain]
    toolchain_install(toolchain)
    redirect to("/"+params[:locale]+'/toolchains/')
  end

  #remove toolchain - not supported at the moment by sdk
  delete '/:locale/toolchains/:toolchain' do
    toolchain = params[:toolchain]
    toolchain_remove(toolchain)
    redirect to('/'+params[:locale]+'/')
  end

  #clear the operation progress output
  post '/actions/clear_output' do
    $status_out.clear
    process_tail_update  
    redirect to(request.referer)
  end

  #add target
  post '/:locale/targets/add' do
    targets_available_update
    target_name = params[:target_name]
    target_url = params[:target_url]
    target_url_list = params[:target_url_list]
    target_toolchain = params[:target_toolchain]
    if target_url_list and target_url_list.length > 0
      target_url = target_url_list
      target = @targets_available.select { |target| target["url"] == target_url }[0]
      target_toolchain = target["toolchain"]
      target_name = target["name"] if not target_name or target_name.size == 0
    end
    target_add(target_name, target_url, target_toolchain)
    redirect to('/'+params[:locale]+'/targets/')
  end
  
  #remove target
  delete '/:locale/targets/:target' do
    target = params[:target]
    target_remove(target)
    redirect to('/'+params[:locale]+'/targets/')
  end

  #refresh target
  post '/:locale/targets/:target/refresh' do
    target = params[:target]
    target_refresh(target)
    redirect to("/"+params[:locale]+'/targets/')
  end

  #sync target
  post '/:locale/targets/:target/sync' do
    target = params[:target] if params[:target]
    target_sync(target)
    redirect to('/' + params[:locale] + '/targets/')
  end

  #set default target
  post '/:locale/targets/:target' do
    default = params[:target] if params[:target]
    ret = target_default_set(default)
    redirect to('/'+params[:locale]+'/targets/')
  end

  #upgrade target
  post '/:locale/targets/:target/upgrade' do
    target = params[:target] if params[:target]
    target_upgrade(target)
    redirect to('/'+params[:locale]+'/targets/')
  end

  #install package
  post '/:locale/targets/:target/:package' do
    target = params[:target]
    package = params[:package]
    package_install(target, package)
    redirect to("/"+params[:locale]+'/targets/' + target)
  end

  #remove package
  delete '/:locale/targets/:target/:package' do
    target = params[:target]
    package = params[:package]
    package_remove(target, package)
    redirect to('/'+params[:locale]+'/targets/' + target)
  end

  #upgrade sdk
  post '/:locale/sdk/' do
    sdk_upgrade()
    redirect to('/'+params[:locale]+'/')
  end

  get '/:locale/info' do  
    content_type 'text/plain'
    ["df", "rpmquery -qa", "cat /proc/version", "/sbin/ifconfig -a", "/sbin/route -n", "mount", "zypper lr", "ping -c 4 81.210.43.226", "ping -c 4 google.com", "free"].map { |command|
      ["*"*80,command,"\n", process_complete(command), "\n"] rescue Exception
    }.flatten.map { |line| line.to_s }.join("\n")
  end		

  helpers do

    def locale_set
      @language = I18n.locale = params[:locale]
    end
    
    def system_language
      if ENV['LANG']
        ENV['LANG'].split("_")[0]
      else
        'C'
      end
    end

    # -------------------------------- Toolchain

    def toolchain_list_update
      $toolchain_list = @toolchain_list = process_complete("sdk-manage --toolchain --list").split.map {|line| line.split(',')  }.map { |tc, i| [tc, i == 'i'] }
    rescue ProcessFailed
      @toolchain_list = ($toolchain_list or []) #FIXME: nil if can't read the list!
    end

    def toolchain_install(name)
      process_start("sdk-manage --toolchain --install '#{name}'", "installing toolchain #{name}", 60*60)
    end

    def toolchain_remove(name)
      process_start("sdk-manage --toolchain --remove '#{name}'", "removing toolchain #{name}", 60*15)
    end

    # -------------------------------- Target

    def targets_list_update
      $targets_list = @targets_list = process_complete("sdk-manage --target --list").split
    rescue ProcessFailed
      @targets_list = ($targets_list or [])
    end

    def target_default_update
      $target_default = @target_default = process_complete("sb2-config showtarget")
    rescue ProcessFailed
      @target_default = $target_default
    end

    def target_add(name, url, toolchain)
      process_start("sdk-manage --target --install '#{name}' '#{toolchain}' '#{url}'", (_ :adding_target) + " #{name}", 60*60)
    end

    def target_remove(name)
      process_start("sdk-manage --target --remove '#{name}'", (_ :removing_target) + " #{name}", 60*15)
    end

    def target_sync(name)
      process_start("sdk-manage --target --sync '#{name}'", (_ :syncing_target) + " #{name}", 60*15)
    end

    def target_refresh(name)
      process_start("sdk-manage --target --refresh '#{name}'", (_ :refreshing_target) + " #{name}", 60*15)
    end

    def target_default_set(name)
      process_complete("sb2-config -d '#{name}'")
    end

    #def target_upgrade(target)
    #	`sdk-manage --target --name #{target} --upgrade` ????
    #end

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

    # -------------------------------- Packages

    def packages_list_update
      @target = params[:target]
      $package_list = @package_list = process_complete("sdk-manage --devel --list #@target").split.map {|line| line.split(',')}.map {|i,j| [i, j == 'i']}
    rescue ProcessFailed
      @package_list = ($package_list or []) #FIXME: nil if can't read the list!
    end

    def package_install(target, package)
      process_start("sdk-manage --devel --install '#{target}' '#{package}'", "installing package #{package}", 60*60)
    end

    def package_remove(target, package)
      process_start("sdk-manage --devel --remove '#{target}' '#{package}'", "removing package #{package}", 60*15)
    end


    # -------------------------------- Sdk

    def sdk_version_update
      $sdk_version = @sdk_version = process_complete("sdk-manage --sdk --version").split("\n")
    rescue ProcessFailed
      @sdk_version = ($sdk_version or [])
    end

    def sdk_upgrade
      process_start("sdk-manage --sdk --upgrade", (_ :upgrading_sdk), 60*60)
    end
    

    # -------------------------------- Process

    def process_tail_update
      # progress background color
      @process_result_class = "process_result_ok"

      if $process
        @refresh_time = 10
        $process_tail += $process.stdout_read(timeout: 0) + $process.stderr_read(timeout: 0)
        split = $process_tail.split("\n",-1).collect { |nline| nline.split("\r",-1)[-1] }
        $process_tail = (split[(-[10,split.size].min)..-1] or []).join("\n")
        $status_out = $process_tail.split("\n").join("<br/>\n").gsub(" ","&nbsp;")
        if $process.status[0] == "Z"
          $process_exitstatus = $process.reap.exitstatus
        
          $process_exit = (_ :finished) + ": " + $process_description + " - " + (_ :exited_with_status) + " " + $process_exitstatus.to_s
          @refresh_time = $process = nil
          if $process_exitstatus != 0
            @process_result_class = "process_result_fail"
          end
        elsif $process.runtime > $process_timeout
          $process.reap
          $process_exit = (_ :timeout) + ": " + $process_description + " - " + (_ :process_killed)
          @refresh_time = $process = nil
          @process_result_class = "process_result_fail"
        end
        if $process
          $status_out = "<b>" + "-"*40 + " " + $process_description + "</b><br/>\n<br/>\n" + $status_out
        else
          $status_out = "<b>" + "-"*40 + " " + $process_exit + "</b><br/>\n<br/>\n" + $status_out
        end
      end
      @status_out = $status_out
    end

    def process_start(command, description, timeout)
      return false if $process
      $process_tail = ""
      $process_description = description
      $process_timeout = timeout
      $process = ShellProcess.new(command)
    end

    def process_complete(command)
      process = ShellProcess.new(command)
      ret = process.stdout_read(timeout: 20).strip
      raise ProcessFailed, command if process.reap.exitstatus != 0
      ret
    end

    def _(*args)
      I18n.t(*args)
    end

  end

end

