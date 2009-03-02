class Initd
  include Nanite::Actor
  expose :status, :start, :stop, :restart, :rc_status, :zap
  
  def status(service)
    parse_status(`/etc/init.d/#{service} status`)
  end
  
  def rc_status(service)
    parse_rc_status(`rc-status -nc`)
  end
  
  def restart(service)
    `/etc/init.d/#{service} restart`.split("\n")
  end
  
  def start(service)
    `/etc/init.d/#{service} start`.split("\n")
  end
  
  def stop(service)
    `/etc/init.d/#{service} stop`.split("\n")
  end
  
  def zap(service)
    `/etc/init.d/#{service} zap`.split("\n")
  end
  
  private
  def parse_status(src)
    src =~ /status: (.*)/
    "status: #{$1}"
  end
  
  def parse_rc_status(src)
    hsh = {}
    process = nil
    src.each do |line|
      case line
      when /^Runlevel: (.*)/
        process = $1
        hsh[$1] = []
      when /^\s+(.*)\s+\[(.*)\]/
        hsh[process] << [$1,$2.strip]
      end  
    end  
    hsh
  end
end