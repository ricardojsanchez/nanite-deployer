# from a pastie by raggi
require 'drb'

class God
  include Nanite::Actor
  expose :status, :stop, :start, :restart

  def initialize
    @socket = "drbunix:///tmp/god.17165.sock"
    reconnect
  end

  def reconnect
    begin; DRb.stop_service; rescue Exception; end
    @god = nil
    DRb.start_service("druby://127.0.0.1:0")
    @god = DRbObject.new(nil, @socket)
  end

  def god(&blk)
    once ||= false
    @god.instance_eval(&blk)
  rescue DRb::DRbConnError => e
    reconnect
    unless once == true
      once = true
      retry
    end
    raise e
  end

  def status payload
    god { status }
  end

  def stop payload
    god { control(payload, 'stop') }
  end

  def start payload
    god { control(payload, 'start') }
  end

  def restart payload
    god { control(payload, 'restart') }
  end
end