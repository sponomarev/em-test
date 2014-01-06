require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class ChatServer < EM::Connection

  @@connections = Array.new

  #
  # EventMachine handlers
  #

  def post_init
    @@connections << self
    @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    puts "A client #{@ip}:#{@port} has connected..."
  end

  def unbind
    @@connections.delete self
    puts "A client #{@ip}:#{@port} has left..."
  end

  #
  # Helpers
  #

  def other_peers
    @@connections.reject { |c| self == c }
  end # other_peers

end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap('INT') { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  host, port = '0.0.0.0', 8082
  EventMachine.start_server host, port, ChatServer

  puts "Listening ChatServer on #{host}:#{port}..."
end