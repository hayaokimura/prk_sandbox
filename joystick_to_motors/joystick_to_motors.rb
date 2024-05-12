require 'adc'
require 'pwm'

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

class Car
  def initialize(joy_stick:)
    @right_motor = Motor.new(positive_pin: 17, negative_pin: 16)
    @left_motor = Motor.new(positive_pin: 19, negative_pin: 18)
    @joy_stick = joy_stick
  end

  def update
    @right_motor.update_duty(right_duty)
    puts "right_duty: " + right_duty.to_s
    @left_motor.update_duty(left_duty)
    puts "left_duty: " + left_duty.to_s
     sleep 1
  end

  def right_duty
    if @joy_stick.vertical_component > 0
      @joy_stick.vertical_component + @joy_stick.horizontal_component
    else
      @joy_stick.vertical_component - @joy_stick.horizontal_component
    end
  end

  def left_duty
    if @joy_stick.vertical_component > 0
      @joy_stick.vertical_component - @joy_stick.horizontal_component
    else
      @joy_stick.vertical_component + @joy_stick.horizontal_component
    end
  end
end

car = Car.new(joy_stick: JoyStick.new)

loop do
  car.update
end
