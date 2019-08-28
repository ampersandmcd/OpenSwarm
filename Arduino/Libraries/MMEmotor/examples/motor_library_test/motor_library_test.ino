//   File: motor_library_test.ino
//
//   Demonstrate use of the MME motor library for driving the TB6612
//   break-out board.  Run one motor forward and backward.
//
//   Gerald Recktenwald, gerry@pdx.edu,  created 2016-11-13

#include <MMEmotor.h>

// Logic pins to control the motors: PWMA and PWMB must be pins capable of PWM output
// User needs to correctly wire these pins to corresponding contacts on TB6612 breakout
#define PWMA 5  // Motor A
#define AIN1 6
#define AIN2 7

#define STBY 8   // Standby pin of TB6612. Shared by both channels

#define PWMB 9   // Motor B
#define BIN1 10
#define BIN2 11

// -- Initialize a Motor object to control the motor on the paper roller
MMEmotor motor  = MMEmotor(BIN1, BIN2, PWMB, STBY);

// ---------------------------------------------------------------------------
void setup() {

  // -- Nothing to do
}

// ---------------------------------------------------------------------------
void loop() {

  int fullSpeed = 255, halfSpeed=127;

  // -- Run the paper motor back and forth.
  motor.forward(fullSpeed);
  delay(1000);
  motor.backward(fullSpeed);
  delay(1000);
  motor.brake();
  delay(1000);

  // Repeat: use lower speed and reverse function to change direction.
  motor.forward(halfSpeed);
  delay(1500);
  motor.reverse();
  delay(1500);
  motor.forward();
  delay(1500);
  motor.reverse();
  delay(1500);
  motor.brake();
  delay(1000);
}


