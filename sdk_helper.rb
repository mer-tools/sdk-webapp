require './shell_process'
require './providers.rb'
require './targets.rb'
require './engine.rb'
require './process.rb'
require_relative 'target_servers'

I18n::Backend::Simple.send(:include, I18n::Backend::Translate)
I18n::Backend::Simple.send(:include, I18n::Backend::TS)
I18n::Backend::Simple.send(:include, I18n::Backend::Fallbacks)
I18n.default_locale = 'en'
I18n.load_path << Dir[ "./i18n/*.ts" ]
I18n.locale = 'en'

def _(*args)
  I18n.t(*args)
end

class SdkHelper < Sinatra::Base

  use Rack::MethodOverride #this is needed for delete methods
  
  configure do
    # logging is enabled by default in classic style applications,
    # so `enable :logging` is not needed
    #  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
    #  file.sync = true
    #  use Rack::CommonLogger, file
    use Rack::CommonLogger
  end

  before do
    Engine.load
    Target.load
  end

  get "/index.css" do
    sass :index
  end

  get '/' do redirect to "/"+system_language+"/targets/"; end
  get '/toolchains/' do redirect to "/"+system_language+"/toolchains/"; end
  get '/targets/' do redirect to "/"+system_language+"/targets/"; end
  get '/updates/' do redirect to "/"+system_language+"/updates/"; end


  get '/:locale/' do
    locale_set
    CCProcess.tail_update
    haml :index, :locals => { :tab => :sdk }
  end

# updates  
  get '/:locale/updates/' do
    locale_set
    CCProcess.tail_update
    haml :updates, :locals => { :tab => :updates }
  end

  post '/:locale/provider/add' do
    locale_set
    Provider.new(params[:provider_name], params[:provider_url])
    Provider.save
    redirect to("/"+params[:locale]+'/updates/')
  end

  delete '/:locale/provider/:provider_id' do
    locale_set
    Provider.delete(params[:provider_id])
    Provider.save
    redirect to('/'+params[:locale]+'/updates/')
  end

  get '/:locale/toolchains/' do
    locale_set
    CCProcess.tail_update
    toolchain_list_update
    haml :toolchains, :locals => { :tab => :toolchains }
  end

# toolchains
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
    CCProcess.clear
    CCProcess.tail_update  
    redirect to(request.referer)
  end

# targets  
  get '/:locale/targets/' do
    locale_set
    CCProcess.tail_update
    toolchain_list_update
    haml :targets, :locals => { :tab => :targets }
  end

  get '/:locale/targets/:target' do
    @target = params[:target]
    locale_set
    CCProcess.tail_update
    packages_list_update
    haml :target, :locals => { :tab => :targets }
  end

  #add target
  post '/:locale/targets/add' do
    if params.include? :template_id then
      t = Provider.targetTemplates[params[:template_id]]
      url = t['url']
      name = params[:local_template_name] || t['name']
      toolchain = t['toolchain']
    else
      name = params[:target_name]
      url = params[:target_url]
      toolchain = params[:target_toolchain]
    end
    target = Target.new(name)
    target.create(url, toolchain)
    redirect to('/'+params[:locale]+'/targets/')
  end
  
  #remove target
  delete '/:locale/targets/:target' do
    Target.get(params[:target]).remove
    redirect to('/'+params[:locale]+'/targets/')
  end

  #refresh target
  post '/:locale/targets/:target/refresh' do
    Target.get(params[:target]).refresh
    redirect to("/"+params[:locale]+'/targets/')
  end

  #sync target
  post '/:locale/targets/:target/sync' do
    Target.get(params[:target]).sync
    redirect to('/' + params[:locale] + '/targets/')
  end

  #upgrade target
  post '/:locale/targets/:target/upgrade' do
    Target.get(params[:target]).upgrade
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
    ["df", "rpmquery -qa", "cat /proc/version", "/sbin/ifconfig -a", "/sbin/route -n", "mount", "zypper lr", "ping -c 4 google.com", "free"].map { |command|
      ["*"*80,command,"\n", CCProcess.complete(command), "\n"] rescue Exception
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
      $toolchain_list = @toolchain_list = CCProcess.complete("sdk-manage --toolchain --list").split.map {|line| line.split(',')  }.map { |tc, i| [tc, i == 'i'] }
    rescue CCProcess::Failed
      @toolchain_list = ($toolchain_list or []) #FIXME: nil if can't read the list!
    end

    def toolchain_install(name)
      CCProcess.start("sdk-manage --toolchain --install '#{name}'", "installing toolchain #{name}", 60*60)
    end

    def toolchain_remove(name)
      CCProcess.start("sdk-manage --toolchain --remove '#{name}'", "removing toolchain #{name}", 60*15)
    end

    # -------------------------------- Packages

    def packages_list_update
      @target = params[:target]
      $package_list = @package_list = CCProcess.complete("sdk-manage --devel --list #@target").split.map {|line| line.split(',')}.map {|i,j| [i, j == 'i']}
    rescue CCProcess::Failed
      @package_list = ($package_list or []) #FIXME: nil if can't read the list!
    end

    def package_install(target, package)
      CCProcess.start("sdk-manage --devel --install '#{target}' '#{package}'", "installing package #{package}", 60*60)
    end

    def package_remove(target, package)
      CCProcess.start("sdk-manage --devel --remove '#{target}' '#{package}'", "removing package #{package}", 60*15)
    end
  end

end
