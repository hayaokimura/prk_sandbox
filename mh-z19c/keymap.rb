require 'uart'

class MH_Z19C
  def initialize(unit:, txd_pin:, rxd_pin:, baudrate:, log_size: DEFAULT_LOG_SIZE)
    UART.new(unit: unit, txd_pin: txd_pin, rxd_pin: rxd_pin, baudrate: baudrate)
  end

  def fetch_data
    @uart.write("\xFF\x01\x86\x00\x00\x00\x00\x00\x79")
    bytes = @uart.read(9)[2,2].bytes
    (bytes[0] << 8) | bytes[1]
  end
end

co2 = MH_Z19C.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 9600)
puts co2.fetch_data


