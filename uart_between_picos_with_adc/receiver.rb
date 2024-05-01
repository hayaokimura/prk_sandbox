require 'uart'

uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
line = ''
loop do
  if c = uart.read(1)
    if c == 'Z'
      puts line.to_i(16)
      line = ''
    else
      line << c
    end
    puts c
    uart.write c
  end
end
