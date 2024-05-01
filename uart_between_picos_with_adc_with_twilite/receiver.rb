require 'uart'

uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
line = ''
loop do
  if c = uart.read(1)
    if c == "\x0a"
      line = line.chomp!
      line = line[1,line.length -1]
      puts "line:" + line if line.length < 11
      puts "x * 1000:" + line[4,4] if line.length < 11
      puts "x: " + (line[4,4].to_i(16).to_f / 1000).to_s if line.length < 11
      line = ''
    else
      line << c
    end
    #puts c
    uart.write c
  end
end
