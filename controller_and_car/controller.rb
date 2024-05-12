require 'uart'
require 'adc'

class JoyStick
  MAX_VOLTAGE = 3.3
  MIN_VOLTAGE = 0.0
  NEUTRAL_VOLTAGE = 1.50
  NEUTRAL_THRESHOLD = 0.05

  def initialize
    @vertical_adc = ADC.new(26)
    @horizontal_adc = ADC.new(27)
  end

  # return: 100 ~ -100
  def vertical_component
    vertical_voltage = @vertical_adc.read
    if vertical_voltage <= NEUTRAL_VOLTAGE + NEUTRAL_THRESHOLD && vertical_voltage > NEUTRAL_VOLTAGE - NEUTRAL_THRESHOLD
      vertical_component = 0
    elsif vertical_voltage > NEUTRAL_VOLTAGE + NEUTRAL_THRESHOLD
      vertical_component = (vertical_voltage - NEUTRAL_VOLTAGE)*2/MAX_VOLTAGE * 30 + 70 # rotate motor over 70%
    else
      vertical_component = (vertical_voltage - NEUTRAL_VOLTAGE)/NEUTRAL_VOLTAGE * 30 - 70 # rotate motor over 70%
    end
  end

  # return: 30 ~ -30
  def horizontal_component
    horizontal_voltage = @horizontal_adc.read
    if horizontal_voltage <= NEUTRAL_VOLTAGE + NEUTRAL_THRESHOLD && horizontal_voltage > NEUTRAL_VOLTAGE - NEUTRAL_THRESHOLD
      horizontal_component = 0
    elsif horizontal_voltage > NEUTRAL_VOLTAGE + NEUTRAL_THRESHOLD
      horizontal_component = (horizontal_voltage - NEUTRAL_VOLTAGE)*2/MAX_VOLTAGE * 30
    else
      horizontal_component = (horizontal_voltage - NEUTRAL_VOLTAGE)/NEUTRAL_VOLTAGE * 30
    end
  end
end


class Controller
  MESSAGE_PREFIX = ":"
  CHILD_DEVICE_ID = "78"
  COMMAND_ID = "01"
  MESSAGE_SUFFIX = "X\r\n"

  VERTICAL_COMPONENT_OFFSET = 100
  HORIZONTAL_COMPONENT_OFFSET = 30

  def initialize
    @joy_stick = JoyStick.new
    @uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
  end

  def send
    message = MESSAGE_PREFIX + CHILD_DEVICE_ID + COMMAND_ID + vertical_message + horizontal_message + MESSAGE_SUFFIX
    puts message
    @uart.write message
  end

  def vertical_message
    vc = @joy_stick.vertical_component.to_i
    # puts "vc: " + vc.to_s
    vc + VERTICAL_COMPONENT_OFFSET >= 0 ? normalize_number(vc + VERTICAL_COMPONENT_OFFSET) : normalize_number(0) 
  end

  def horizontal_message
    hc = @joy_stick.horizontal_component.to_i
    # puts "hc: " + hc.to_s
    hc + HORIZONTAL_COMPONENT_OFFSET >= 0 ? normalize_number(hc + HORIZONTAL_COMPONENT_OFFSET) : normalize_number(0)
  end

  def normalize_number(number)
    string_number = number.to_s
    ("0" * (4 - string_number.length)) + string_number
  end
end

controller = Controller.new

loop do
  controller.send
  sleep 0.05
end
