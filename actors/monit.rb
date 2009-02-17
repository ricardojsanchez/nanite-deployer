class Monit < Nanite::Actor
  expose :status, :start, :stop, :restart,
         :monitor, :unmonitor, :reload, :validate
  
  def status(payload)
    parse_monit_status(`monit status`)
  end
  
  def restart(service)
    if system("monit restart #{service}")
      parse_monit_status(`monit status`)
    else
      :fail
    end    
  end
  
  def start(service)
    if system("monit start #{service}")
      parse_monit_status(`monit status`)
    else
      :fail
    end    
  end
  
  def stop(service)
    if system("monit stop #{service}")
      parse_monit_status(`monit status`)
    else
      :fail
    end    
  end
  
  def monitor(service)
    if system("monit monitor #{service}")
      parse_monit_status(`monit status`)
    else
      :fail
    end    
  end
  
  def unmonitor(service)
    if system("monit unmonitor #{service}")
      parse_monit_status(`monit status`)
    else
      :fail
    end    
  end
  
  def reload(service)
    system('monit reload')
    parse_monit_status(`monit status`)
  end
  
  def validate(service)
    system('monit validate')
    parse_monit_status(`monit status`)
  end
  
  private
  
  def parse_monit_status(src)
    hsh = {}
    process = nil
    src.each do |line|
      case line
      when /^Process (.*)/
        process = $1.gsub(/'/, '')
        hsh[process] = {}
      when /^System (.*)/  
        process = $1.gsub(/'/, '')
        hsh[process] = {}
      when /^\s+status\s\s+(.*)/
        hsh[process]['status'] = $1
      when /^\s+monitoring status\s+(.*)/
        hsh[process]['monit_status'] = $1
      when /^\s+pid\s\s+(.*)/
        hsh[process]['pid'] = $1
      when /^\s+parent pid\s+(.*)/
        hsh[process]['pid'] = $1
      when /^\s+uptime\s+(.*)/
        hsh[process]['uptime'] = $1
      when /^\s+childrens\s+(.*)/
        hsh[process]['childrens'] = $1
      when /^\s+memory kilobytes\s\s+(.*)/
        hsh[process]['memory_kb'] = $1
      when /^\s+memory kilobytes total\s+(.*)/
        hsh[process]['memory_kb_total'] = $1
      when /^\s+memory percent\s\s+(.*)/
        hsh[process]['memory_percent'] = $1
      when /^\s+memory percent total\s+(.*)/
        hsh[process]['memory_percent_total'] = $1
      when /^\s+cpu percent\s+(.*)/
        hsh[process]['cpu_percent_total'] = $1
      when /^\s+cpu percent total\s+(.*)/
        hsh[process]['cpu_percent_total'] = $1
      when /^\s+data collected\s+(.*)/
        hsh[process]['last_collection'] = $1
      when /^\s+load average\s+(.*)/
        hsh[process]['load_average'] = $1
      when /^\s+data collected\s+(.*)/
        hsh[process]['cpu'] = $1
      when /^\s+cpu\s+(.*)/
        hsh[process]['memory usage'] = $1
      end
    end  
    hsh
  end
end
