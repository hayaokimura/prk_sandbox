require 'adc'
require 'pwm'

class Motor
  MAX_VOLTAGE = 3.3
  NORMAL_LOTATION_MIN_VOLTAGE = 1.7
  NORMAL_LOTATION_RANGE = MAX_VOLTAGE - NORMAL_LOTATION_MIN_VOLTAGE

  def initialize
    @output1 = PWM.new(16, frequency: 100000, duty: 0)
    @adc = ADC.new(26)
  end

  def update
    raw_normal_lotation = @adc.read - NORMAL_LOTATION_MIN_VOLTAGE
    puts "raw_normal_lotation"
    puts raw_normal_lotation
    normal_lotation = raw_normal_lotation >= 0 ? raw_normal_lotation : 0
    puts "normal_lotation"
    puts normal_lotation
    duty = normal_lotation * 100 / NORMAL_LOTATION_RANGE
    puts "duty"
    puts duty
    @output1.duty(duty)
  end
end

pin = GPIO.new(25, GPIO::OUT)
pin.write(1)
motor = Motor.new

loop do
  motor.update
end
