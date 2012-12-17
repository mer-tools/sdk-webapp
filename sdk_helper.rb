require './shell_process'

class ProcessFailed < Exception; end

class SdkHelper < Sinatra::Base

	use Rack::MethodOverride #this is needed for delete methods

	get "/index.css" do
		sass :index
	end

	######## default routes ########
	get '/' do
		process_tail_update
		sdk_version_update
		haml :index
	end
	
	get '/toolchains/' do
		process_tail_update
		toolchain_list_update
		haml :toolchain
	end

	get '/targets/' do
		process_tail_update
		toolchain_list_update
		target_default_update
		targets_list_update
		haml :targets
	end

	#install toolchain
	post '/toolchains/:toolchain' do
		toolchain = params[:toolchain]
		toolchain_install(toolchain)
		redirect to('/toolchains/')
	end

	#remove toolchain - not supported at the moment by sdk
	delete '/toolchains/:toolchain' do
		toolchain = params[:toolchain]
		toolchain_remove(toolchain)
		redirect to('/')
	end

	#add target
	post '/targets/add' do
		target_name = params[:target_name]
		target_url = params[:target_url]
		target_toolchain = params[:target_toolchain]
		target_add(target_name, target_url, target_toolchain)
		redirect to('/targets/')
	end
	
	#TODO: remove target

	#set default target
	post '/targets/:target' do
		default = params[:target] if params[:target]
		ret = target_default_set(default)
		redirect to('/targets/')
	end

	#upgrade target
	post '/targets/:target/upgrade' do
		target = params[:target] if params[:target]
		target_upgrade(target)
		redirect to('/targets/')
	end

	#upgrade sdk
	post '/sdk/' do
		sdk_upgrade()
		redirect to('/')
	end

	####### helper functions #######
	helpers do

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
			process_start("sdk-manage --target --install '#{name}' '#{toolchain}' '#{url}'", "adding target #{name}", 60*60)
		end

		def target_remove(name)
			process_start("sdk-manage --target --remove '#{name}'", "removing target #{name}", 60*15)
		end

		def target_default_set(name)
			process_complete("sb2-config -d '#{name}'")
		end

		#def target_upgrade(target)
		#	`sdk-manage --target --name #{target} --upgrade` ????
		#end

		# -------------------------------- Sdk

		def sdk_version_update
			$sdk_version = @sdk_version = process_complete("sdk-manage --sdk --version").split("\n")
		rescue ProcessFailed
			@sdk_version = ($sdk_version or [])
		end

		def sdk_upgrade
			process_start("sdk-manage --sdk --upgrade", "upgrading SDK", 60*60)
		end
		
		# -------------------------------- Process

		def process_tail_update
			@status_out = $status_out
			return unless $process

			$process_tail += $process.stdout_read(timeout: 0) + $process.stderr_read(timeout: 0)
			split = $process_tail.split("\n",-1).collect { |nline| nline.split("\r",-1)[-1] }
			$process_tail = (split[(-[10,split.size].min)..-1] or []).join("\n")
			$status_out = $process_tail.split("\n").join("<br/>\n").gsub(" ","&nbsp;")
			if $process.status[0] == "Z"
				$process_exit = "FINISHED " + $process_description + " - exited with status " + $process.reap.exitstatus.to_s
				$process = nil
			elsif $process.runtime > $process_timeout
				$process.reap
				$process_exit = "TIMEOUT " + $process_description + " - process killed"
				$process = nil
			end
			if $process
				$status_out = "<b>" + "-"*40 + " " + $process_description + "</b><br/>\n<br/>\n" + $status_out
			else
				$status_out = "<b>" + "-"*40 + " " + $process_exit + "</b><br/>\n<br/>\n" + $status_out
			end
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
			ret = process.stdout_read(timeout: 10).strip
			raise ProcessFailed, command if process.reap.exitstatus != 0
			ret
		end

	end
end

