require 'uart'
require 'adc'

#class DutySender
#  def initialize
#    @uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
#    @adc = ADC.new(26)
#  end
#
#  def send
#    #duty = (@adc.read * 100 / 3.3).to_i
#    #puts duty.to_s(2)
#    puts 'ac'
#    @uart.write 'ac'
#  end
#end

#duty_sender = DutySender.new
adc = ADC.new(26)
uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
loop do
  c = (adc.read * 1000).to_i
  puts c
  puts c.to_s(16).to_i(16)
  sleep 1
  uart.write c.to_s(16) + 'Z'
end
