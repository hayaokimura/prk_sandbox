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
adc_vertical = ADC.new(26)
adc_holizontal = ADC.new(27)
uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
loop do
  adc_vertical_result = (adc_vertical.read * 1000).to_i.to_s(16).upcase
  adc_holizontal_result = (adc_holizontal.read * 1000).to_i.to_s(16).upcase
  if adc_vertical_result.length < 4
    adc_vertical_result = ("0" * (4 - adc_vertical_result.length)) + adc_vertical_result
  end
  if adc_holizontal_result.length < 4
    adc_holizontal_result = ("0" * (4 - adc_holizontal_result.length)) + adc_holizontal_result
  end
  send_message = ":7801" + adc_vertical_result + adc_holizontal_result + "X\r\n"
  puts send_message
  uart.write send_message
  sleep 1
end
