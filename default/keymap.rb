# Initialize a Keyboard
kbd = Keyboard.new

# Initialize GPIO assign
# Connect switches to GPIO8,12 and GPIO0
kbd.init_pins(
  [ 0 ],
  [ 12, 8 ]
)

# default layer (should be added at first)
kbd.add_layer :default, %i(
  KC_RIGHT    KC_LEFT
)

# Start the keyboard
kbd.start!
