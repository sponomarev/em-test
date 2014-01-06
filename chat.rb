require 'rubygems' # or use Bundler.setup
require 'eventmachine'

class ChatServer < EM::Connection

  attr_reader :ip, :port, :username

  @@connections = Array.new

  #
  # EventMachine handlers
  #

  def post_init
    @port, @ip = Socket.unpack_sockaddr_in(get_peername)
    @username = nil
    puts "A client #{@ip}:#{@port} has connected..."

    ask_username
  end

  def unbind
    @@connections.delete self
    puts "A client #{@ip}:#{@port} has left..."
  end

  def receive_data(data)
    if entered_username?
      handle_chat_message data.strip
    else
      handle_username data.strip
    end
  end

  #
  # Message handling
  #

  def handle_chat_message(msg)
    if command?(msg)
      self.handle_command(msg)
    else
      self.announce(msg, "#{@username}:")
    end
  end

  #
  # Commands handling
  #

  def command?(input)
    input =~ /exit$/i
  end

  def handle_command(cmd)
    case cmd
      when /exit$/i then
        self.close_connection
    end
  end

  #
  # Username handling
  #

  def entered_username?
    !@username.nil? && !@username.empty?
  end

  def handle_username(input)
    if input.empty?
      send_line 'Blank usernames are not allowed. Try again.'
      ask_username
    else
      @username = input
      @@connections << self
      announce "#{@username} has joined the room\n"
      puts "A client #{@ip}:#{@port} has joined as #{@username}"
      send_line("[info] Ohai, #{@username}")
    end
  end

  def ask_username
    self.send_line('[info] Enter your username:')
  end

  #
  # Helpers
  #

  def announce(msg = nil, prefix = '[server]')
    @@connections.each { |c| c.send_line("#{prefix} #{msg}") } unless msg.empty?
  end

  def other_peers
    @@connections.reject { |c| self == c }
  end

  def send_line(line)
    self.send_data "#{line}\n"
  end

end

EventMachine.run do
  # hit Control + C to stop
  Signal.trap('INT') { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  host, port = '0.0.0.0', 8082
  EventMachine.start_server host, port, ChatServer

  puts "Listening ChatServer on #{host}:#{port}..."
end