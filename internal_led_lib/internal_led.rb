class InternalLED
    def initialize
        @pin = GPIO.new(25, GPIO::OUT)
        @state = 1
    end

    def flip
        @state = @state == 0 ? 1 : 0
        @pin.write @state
    end
end