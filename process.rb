require './shell_process'

class CCProcess
  class Failed < Exception; end
  REFRESH_PERIOD=5

  @@process=@@status_out=@@refresh_time=@@process_exitstatus=nil
  def self.tail_update
    # progress background color
    @@process_result_class = "process_result_ok"

    if @@process
      @@refresh_time = REFRESH_PERIOD
      @@process_tail += @@process.stdout_read(timeout: 0) + @@process.stderr_read(timeout: 0)
      split = @@process_tail.split("\n",-1).collect { |nline| nline.split("\r",-1)[-1] }
      @@process_tail = (split[(-[10,split.size].min)..-1] or []).join("\n")
      @@status_out = @@process_tail.split("\n").join("<br/>\n").gsub(" ","&nbsp;")
      if @@process.status[0] == "Z"
        @@process_exitstatus = @@process.reap.exitstatus
        
        @@process_exit = (_ :finished) + ": " + @@process_description + " - " + (_ :exited_with_status) + " " + @@process_exitstatus.to_s
        @@refresh_time = @@process = nil
        if @@process_exitstatus != 0
          @@process_result_class = "process_result_fail"
        end
      elsif @@process.runtime > @@process_timeout
        @@process.reap
        @@process_exit = (_ :timeout) + ": " + @@process_description + " - " + (_ :process_killed)
        @@refresh_time = @@process = nil
        @@process_result_class = "process_result_fail"
      end
      if @@process
        @@status_out = "<b>" + "-"*40 + " " + @@process_description + "</b><br/>\n<br/>\n" + @@status_out
      else
        @@status_out = "<b>" + "-"*40 + " " + @@process_exit + "</b><br/>\n<br/>\n" + @@status_out
      end
    end
    @@status_out = @@status_out
  end

  def self.clear()
    @@status_out.clear
  end

  def self.exists
    (@@status_out && @@status_out.size > 0)
  end

  def self.is_running
    @@process
  end

  def self.status_out
    @@status_out
  end

  def self.result_class
    @@process_result_class
  end

  def self.refresh_time
    @@refresh_time
  end

  def self.start(command, description, timeout)
    return false if @@process
    @@process_tail = ""
    @@process_description = description
    @@process_timeout = timeout
    @@process = ShellProcess.new(command)
  end

  def self.complete(command)
    process = ShellProcess.new(command)
    ret = process.stdout_read(timeout: 20).strip
    raise Failed, command if process.reap.exitstatus != 0
    ret
  end
end
