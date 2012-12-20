require 'minitest/autorun'

require './shell_process.rb'

describe ShellProcess do

	describe "initialized with properly terminating command" do

		describe "only" do

			it "must return ShellProcess object" do
				ShellProcess.new("echo -n xxx").must_be_kind_of ShellProcess
			end
			
			it "correctly reports Z and non-Z status of command" do
				process = ShellProcess.new("sleep 0.1")
				non_zombie_cycles = 0
				non_zombie_cycles += 1 while process.status[0] != "Z"
				non_zombie_cycles.must_be :>, 0
				process.status[0].must_equal "Z"
			end

			it "correctly reports exitstatus" do
				ShellProcess.new("true").wait.exitstatus.must_equal 0
				ShellProcess.new("false").wait.exitstatus.must_equal 1
			end

			it "allows nonblock-reading command's stdout" do
				process = ShellProcess.new("echo -n xxx")
				process.wait
				process.stdout_read(timeout: 0).must_equal "xxx"
			end

			it "allows nonblock-reading command's stderr" do
				process = ShellProcess.new("echo -n xxx 1>&2")
				process.wait
				process.stderr_read(timeout: 0).must_equal "xxx"
			end

			it "allows block-reading command's stdout" do
				process = ShellProcess.new("echo -n xxx")
				process.stdout_read(timeout: 4).must_equal "xxx"
			end

			it "allows checking roughly how much time passed since process start" do
				t1 = Time.new
				process = ShellProcess.new("sleep 0.1")
				process.wait
				d = Time.new - t1
				process.runtime.must_be_close_to d, 0.1
			end

			it "allows terminating process" do
				process = ShellProcess.new("sleep 10")
				process.kill
				process.status[0].must_equal "Z"
			end
				
			it "allows killing process" do
				process = ShellProcess.new("sleep 10")
				process.kill(9)
				process.status[0].must_equal "Z"
			end

			it "allows closing all it's std pipes" do
				process = ShellProcess.new("sleep 10")
				process.close
				process.stdout.closed?.must_equal true
				process.stderr.closed?.must_equal true
				process.stdin.closed?.must_equal true
			end

			it "can be reaped" do
				process = ShellProcess.new("echo xxx")
				sleep 0.5
				start = Time.now
				process.reap
				stop = Time.now
				(stop - start).must_be :<, 1
				process.wait.exitstatus.must_equal 0
			end


		end

	end


	describe "initialized with properly terminating, long running command" do

		describe "only" do

			it "allows block-reading command's stdout as soon as command ends" do
				process = ShellProcess.new("echo -n xxx")
				start = Time.now
				process.stdout_read(timeout: 4).must_equal "xxx"
				stop = Time.now
				(stop - start).must_be :<, 2
			end

			it "allows block-reading command's stdout, blocking not more for timeout" do
				process = ShellProcess.new("echo -n xxx; sleep 2; echo -n yyy")
				start = Time.now
				process.stdout_read(timeout: 1).must_equal "xxx"
				stop = Time.now
				(stop - start).must_be :<, 1.5
				(stop - start).must_be :>, 0.5
			end

			it "can be killed and reaped" do
				process = ShellProcess.new("sleep 10")
				start = Time.now
				process.reap
				stop = Time.now
				(stop - start).must_be :<, 1
				process.wait.termsig.must_equal 9
			end

		end

	end

	describe "initialized with command and" do

		describe "non-hash argument" do

			it "must raise exception" do
				assert_raises ArgumentError do
					ShellProcess.new("",1)
				end
			end

		end

	end

	describe "initialized without command" do

		it "must raise exception" do
			assert_raises ArgumentError do
				ShellProcess.new()
			end
		end

	end

end

