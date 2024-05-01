require 'adc'
require 'pwm'

class Motor
  MAX_VOLTAGE = 3.3
  NORMAL_LOTATION_MIN_VOLTAGE = 1.7
  NORMAL_LOTATION_RANGE = MAX_VOLTAGE - NORMAL_LOTATION_MIN_VOLTAGE
  REVERSAL_LOTATION_MAX_VOLTAGE = 1.5
  REVERSAL_LOTATION_RANGE = REVERSAL_LOTATION_MAX_VOLTAGE

  def initialize
    @output1 = PWM.new(16, frequency: 100000, duty: 0)
    @output2 = PWM.new(17, frequency: 100000, duty: 0)
    @adc = ADC.new(26)
  end

  def update
    adc_result = @adc.read
    raw_normal_lotation = adc_result - NORMAL_LOTATION_MIN_VOLTAGE
    raw_reversal_lotation = REVERSAL_LOTATION_MAX_VOLTAGE - adc_result
    normal_lotation = raw_normal_lotation >= 0 ? raw_normal_lotation : 0
    reversal_lotation = raw_reversal_lotation >= 0 ? raw_reversal_lotation : 0
    normal_duty = normal_lotation * 100 / NORMAL_LOTATION_RANGE
    reversal_duty = reversal_lotation * 100 / REVERSAL_LOTATION_RANGE
    @output1.duty(normal_duty)
    @output2.duty(reversal_duty)
  end
end

pin = GPIO.new(25, GPIO::OUT)
pin.write(1)
motor = Motor.new

loop do
  motor.update
end
