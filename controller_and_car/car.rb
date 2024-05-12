require 'pwm'
require 'uart'

class Motor
  def initialize(positive_pin:, negative_pin:)
    @output_positive = PWM.new(positive_pin, frequency: 100000, duty: 0)
    @output_negative = PWM.new(negative_pin, frequency: 100000, duty: 0)
  end

  def update_duty(duty)
    if duty >= 0
      @output_positive.duty(duty)
      @output_negative.duty(0)
    else
      @output_positive.duty(0)
      @output_negative.duty(-duty)
    end
  end
end

class Receiver
  VERTICAL_COMPONENT_OFFSET = 100
  HORIZONTAL_COMPONENT_OFFSET = 30

  attr_reader :vertical_component, :horizontal_component

  def initialize
    @uart = UART.new(unit: :RP2040_UART0, txd_pin: 0, rxd_pin: 1, baudrate: 115200)
    @line = ''
    @vertical_component = 0
    @horizontal_component = 0
  end

  def receive
    c = @uart.read(1)
    return nil unless c
    if c != "\x0a"
      @line << c
      return nil
    end
    return nil unless @line
    line = @line.chomp
    @line = '' 
    line = line[1,line.length -1]
    return nil unless line.length == 14 || line[0,4].to_i(16) == 1

    # puts 'line:' + line

    @vertical_component = line[4,4].to_i - VERTICAL_COMPONENT_OFFSET
    @horizontal_component = line[8,4].to_i - HORIZONTAL_COMPONENT_OFFSET
    puts 'vertical component: ' + @vertical_component.to_s
    puts 'horizontal component: ' + @horizontal_component.to_s
  end

end

class Car
  def initialize
    @left_motor = Motor.new(positive_pin: 17, negative_pin: 16)
    @right_motor = Motor.new(positive_pin: 19, negative_pin: 18)
    @receiver = Receiver.new
  end

  def run
    loop do
      update
    end
  end

  def update
    @receiver.receive
    @right_motor.update_duty(right_duty)
    @left_motor.update_duty(left_duty)
    #puts "right_duty: " + right_duty.to_s
    #puts "left_duty: " + left_duty.to_s
  end

  def right_duty
    if @receiver.vertical_component > 0
      @receiver.vertical_component + @receiver.horizontal_component
    else
      @receiver.vertical_component - @receiver.horizontal_component
    end
  end

  def left_duty
    if @receiver.vertical_component > 0
      @receiver.vertical_component - @receiver.horizontal_component
    else
      @receiver.vertical_component + @receiver.horizontal_component
    end
  end
end

car = Car.new

car.run
