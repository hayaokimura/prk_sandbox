require 'uart'

uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
loop do
  puts 'read'
  if c = uart.read(1)
    uart.write c
    puts c
  end
end
