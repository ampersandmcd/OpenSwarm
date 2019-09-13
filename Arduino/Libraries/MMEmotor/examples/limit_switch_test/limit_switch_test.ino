//   File: limit_switch_test.ino
//
//   Demonstrate use of limit switches to reverse motion of the motor.
//   Light LEDs to indicate limit switch condition
//
//   Gerald Recktenwald, gerry@pdx.edu,  created 2016-11-13

// -- LEDA and LEDB are LEDs used to indicate status of limit switches A and B
#define  LEDA  13    //  Digital I/O pin number 
#define  LEDB  12    //  Digital I/O pin number

// -- Data used to configure interrupt pins.  See attachInterrupt()
#define  LIMIT_A_PIN  2         //  I/O pin for interrupt on limit switch labeled A
#define  LIMIT_B_PIN  3         //  I/O pin for interrupt on limit switch labeled B
#define  SWITCH_A_INTERRUPT 0   // Interrupt number 0 is on pin 2
#define  SWITCH_B_INTERRUPT 1   // Interrupt number 1 is on pin 3

// -- limit_A_tripped and limit_B_tripped are flags used to indicate staus of
//    limit switch is that a limit switch has been tripped
volatile bool limit_A_tripped = false;
volatile bool limit_B_tripped = false;


// ---------------------------------------------------------------------------
void setup() {

  // -- Set up interrupts for limit switches.  Switches are wired with a
  //    10k pull-up resistor tied to logic level HIGH.  When the normally
  //    open (NO) switch is contacted, the input pin goes LOW.  Use the
  //    FALLING mode instead of the LOW mode on the interrupt.  FALLING
  //    allows the interrupt handler to set a flag which is then read and
  //    and reset in the loop() function.  If the LOW mode is used instead,
  //    the interrupt is fired only while the interrupt pin is held low.
  //    That does not allow processing elsewhere in the loop() function.
  //    Note that adding processing to the interrupt handler is a bad idea
  //    because the interrupt handler needs to be fast to allow it to
  //    respond to other interrupts.
  //
  attachInterrupt(SWITCH_A_INTERRUPT, handle_interrupt_A, FALLING);
  attachInterrupt(SWITCH_B_INTERRUPT, handle_interrupt_B, FALLING);

  // -- Set up output channels LEDs that indicate limit switches
  pinMode(LEDA, OUTPUT);
  pinMode(LEDB, OUTPUT);
}

// ---------------------------------------------------------------------------
void loop() {

  // -- Monitor whether limit switches have been tripped.
  //    If so, wait 500 ms and then turn the LED off
  //    Interrrupt handlers turn on the LED and set the flag indicating
  //    that the switch has been tripped
  if ( limit_A_tripped ) {
    delay(500);
    digitalWrite(LEDA, LOW);
    limit_A_tripped = false;
  } 

  if ( limit_B_tripped ) {
    delay(500);
    digitalWrite(LEDB, LOW);
    limit_B_tripped = false;
  } 

}

// ------------------------------------------------------------
//   Interrupt handler for the limit switch.  Use software debounce
//   to ignore events happening less than 200 msec apart.
//
void  handle_interrupt_A()
{
  static unsigned long last_interrupt_time = 0;       //  Zero only on startup
 
  unsigned long interrupt_time = millis();            //  Always read the clock
  //  -- Ignore events separated by less than 200 msec
  if ( interrupt_time - last_interrupt_time > 200 ) {
    limit_A_tripped = true;
    digitalWrite(LEDA, HIGH);
  }
  last_interrupt_time = interrupt_time;
}

// ------------------------------------------------------------
//   Interrupt handler for the limit switch.  Use software debounce
//   to ignore events happening less than 200 msec apart.
//
void  handle_interrupt_B()
{
  static unsigned long last_interrupt_time = 0;       //  Zero only on startup
 
  unsigned long interrupt_time = millis();            //  Always read the clock
  //  -- Ignore events separated by less than 200 msec
  if ( interrupt_time - last_interrupt_time > 200 ) {
    limit_B_tripped = true;
    digitalWrite(LEDB, HIGH);
  }
  last_interrupt_time = interrupt_time;
}




