require "rubygems"
require "bundler/setup"

Bundler.require 


class ShellProcess
	
	attr_reader :pid, :stdin, :stdout, :stderr, :stdout_data, :stderr_data

	def initialize(command, *params)
		params ||= [{}]
		raise ArgumentError, "execute needs named arguments" if params.size > 1 or (params.size >0 and not params[].kind_of?(Hash)) #test
		@pid, @stdin, @stdout, @stderr = Open4.popen4(command)
		@start_time = Time.new
	end

	def fetch(pipe,*params)
		params ||= [{}]
		raise ArgumentError, "fetch needs named arguments" if params.size > 1 or (params.size >0 and not params[0].kind_of?(Hash)) #test
		params = params[0]
		ret = ""
		eof = false
		start = Time.now
		loop {
			begin #FIXME: select
				ret += pipe.read_nonblock(1000000) 
			rescue Errno::EAGAIN
			rescue EOFError
				eof = true
			end	
			break if params[:timeout] and (params[:timeout] < (Time.new - start))
			break if eof and status[0] == "Z"
			sleep 0.1
		}
		ret
	end


	def stdout_read(*params)
		fetch(@stdout, *params)
	end
	
	def stderr_read(*params)
		fetch(@stderr, *params)
	end

	def status
		`ps --no-headers -o stat -p #{@pid}`.chomp.split("")
	end

	def wait
		@exitstatus ||= Process.waitpid2(@pid)[1]
	end

	def runtime
		Time.new - @start_time
	end

	def kill(signal=15)
		`sudo kill -#{signal} #{@pid}`
	end

	def reap
		kill(9)
		close
		wait
	end

	def close
		@stdin.close
		@stdout.close
		@stderr.close
	end

end



