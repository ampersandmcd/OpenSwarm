//   File: motor_pong.ino
//
//   Demonstrate use of the MME motor library for driving the TB6612
//   break-out board.  Run the inkJet motor until limit switches are contacted
//   which is the signal to reverse direction of the motor
//
//   Gerald Recktenwald, gerry@pdx.edu,  created 2016-11-13

#include <MMEmotor.h>

// -- LEDA and LEDB are LEDs used to indicate status of limit switches A and B
#define  LEDA  13    //  Digital I/O pin number 
#define  LEDB  12    //  Digital I/O pin number

// -- Data used to configure interrupt pins.  See attachInterrupt()
#define  LIMIT_A_PIN  2         //  I/O pin for interrupt on limit switch labeled A
#define  LIMIT_B_PIN  3         //  I/O pin for interrupt on limit switch labeled B
#define  SWITCH_A_INTERRUPT 0   // Interrupt number 0 is on pin 2
#define  SWITCH_B_INTERRUPT 1   // Interrupt number 1 is on pin 3

// -- limit_A_tripped and limit_B_tripped are flags indicating state of the
//    limit switches.  True if a limit switch has been tripped. False otherwise
volatile bool limit_A_tripped = false;
volatile bool limit_B_tripped = false;

// Logic pins to control the motors: PWMA and PWMB must be pins capable of PWM output
// User needs to correctly wire these pins to corresponding contacts on TB6612 breakout
#define PWMA 5  // Motor A
#define AIN1 6
#define AIN2 7

#define STBY 8   // Standby pin of TB6612. Shared by both channels

#define PWMB 9   // Motor B
#define BIN1 10
#define BIN2 11

// -- Initialize MMEmotor objects that control motors on the paper roller and ink jet carriage
MMEmotor paperMotor  = MMEmotor(BIN1, BIN2, PWMB, STBY);
MMEmotor inkJetMotor = MMEmotor(AIN1, AIN2, PWMA, STBY);

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

  // -- Set up output channels for LEDs that indicate limit switch activity
  pinMode(LEDA, OUTPUT);
  pinMode(LEDB, OUTPUT);

  // -- Blink LEDs while waiting for system to set up.  It's probably not
  //    necessary, but who can resist blinky lights.  
  for ( int i=1; i<=5; i++ ) {
    digitalWrite(LEDA, HIGH);
    digitalWrite(LEDB, HIGH);
    delay(200);
    digitalWrite(LEDA, LOW);
    digitalWrite(LEDB, LOW);
    delay(200);
  }

  // -- Now that we're done waiting for the blinking startup, turn on the
  //    motor that drives the ink jet carriage.  This is the only time we
  //    set the motor speed.  When the carriage hits a limit switch, the
  //    interrupt handler reverses the direction of the motor driving the
  //    ink jet carriage.  Otherwise there is no further control of the
  //    motor driving the ink jet carriage.
  inkJetMotor.forward(150);    //  argument is speed:  0 <= speed <= 255
}

// ---------------------------------------------------------------------------
void loop() {

  int LED_delay = 300;
  int paper_motor_speed = 140;

  // -- Monitor whether limit switches have been tripped.  If so, wait LED_delay ms
  //    and then turn the LED off.  While waiting, spin the paper motor.
  //    Interrrupt handlers turn on the LED and set the flag indicating
  //    that the switch has been tripped.  Last act here is to reset the flag.
  if ( limit_A_tripped ) {
    paperMotor.forward(paper_motor_speed);
    delay(LED_delay);
    digitalWrite(LEDA, LOW);
    paperMotor.brake();
    limit_A_tripped = false;
  } 

  if ( limit_B_tripped ) {
    paperMotor.backward(paper_motor_speed);
    delay(LED_delay);
    digitalWrite(LEDB, LOW);
    paperMotor.brake();
    limit_B_tripped = false;
  }

}

// ------------------------------------------------------------
//   Interrupt handler for the limit switch A.  Use software debounce
//   to ignore events happening less than 200 msec apart.
//
void  handle_interrupt_A()
{
  static unsigned long last_interrupt_time = 0;       //  Zero only on startup
 
  unsigned long interrupt_time = millis();            //  Always read the clock
  
  //  -- Ignore events separated by less than 200 msec
  if ( interrupt_time - last_interrupt_time > 200 ) {
    limit_A_tripped = true;
    digitalWrite(LEDA, HIGH);    // Turn on LED to indicate switch A
    inkJetMotor.reverse();       // Reverse motor direction
  }
  last_interrupt_time = interrupt_time;   //  Save for next debounce check
}

// ------------------------------------------------------------
//   Interrupt handler for the limit switch B.  Use software debounce
//   to ignore events happening less than 200 msec apart.
//
void  handle_interrupt_B()
{
  static unsigned long last_interrupt_time = 0;       //  Zero only on startup
 
  unsigned long interrupt_time = millis();            //  Always read the clock

  //  -- Ignore events separated by less than 200 msec
  if ( interrupt_time - last_interrupt_time > 200 ) {
    limit_B_tripped = true;
    digitalWrite(LEDB, HIGH);    // Turn on LED to indicate switch A
    inkJetMotor.reverse();       // Reverse motor direction
  }
  last_interrupt_time = interrupt_time;   //  Save for next debounce check
}


