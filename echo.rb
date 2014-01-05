require 'rubygems'
require 'eventmachine'

class EchoServer < EventMachine::Connection

  def post_init
    puts 'Соединение с сервером'
  end

  def receive_data(data)
    send_data data
    close_connection if data =~ /quit/i
  end

  def unbind
    puts 'Соединение закрыто'
  end

end

EventMachine::run {
  Signal.trap('INT') { EventMachine.stop }
  Signal.trap('TERM') { EventMachine.stop }

  EventMachine::start_server '', 8081, EchoServer
}