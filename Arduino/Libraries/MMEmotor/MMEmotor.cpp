//  File: MMEmotor.cpp
//
//  C++ Code for object-oriented interface to TB6612 motor controller based
//  on an earlier version of this library for the Pololu MD018 controller
//
//  Gerald Recktenwald, gerry@pdx.edu, Created 2016-11-13
//  Pololu MD018 library created by GWR 2013-07-03
//
//  Updates:
//    2016-11-13 -- initial version, changes from Pololu library
//       * Modified to be compatible with TB6612 motor driver, and now no longer
//          compatible with Pololu Motor Controller MD018
//       * Add Standby pin, though not used yet
//       * Added option forward(int speedVal) and backward(int speedVal) methods 
//       * Removed unused _hasStarted private variable and public begin() method
//           Maybe that's not a good idea because we should make sure the MMEmotor
//           object is correctly initialized. 
//           See this thread:  http://forum.arduino.cc/index.php/topic,45794.0.html
//
//   2016-11-25:  Minor tweaks to documentation

//  #include "WProgram.h"    // Not needed with current versions of Arduino toolchain

#include "MMEmotor.h"

// --- constructor
MMEmotor::MMEmotor( int In1, int In2, int PWMpin, int SBpin) {
  _InPin1 = In1;
  _InPin2 = In2;
  _PWMpin = PWMpin;
  _SBYpin = SBpin;
  
  _direction = 0;       //   0 for unset/brake/off, +1 for forward, -1 for reverse
  _speed = 0;
}

// ------------------------------------------------------------------------------
void MMEmotor::brake() {
    digitalWrite( _InPin1, HIGH );
    digitalWrite( _InPin2, HIGH );
    digitalWrite( _SBYpin, HIGH );
    _direction = 0;
}

// ------------------------------------------------------------------------------
void MMEmotor::off() {
    digitalWrite( _InPin1, LOW );
    digitalWrite( _InPin2, LOW );
    digitalWrite( _SBYpin, HIGH );
    _direction = 0;
}

// ------------------------------------------------------------------------------
void MMEmotor::standby() {
    digitalWrite( _SBYpin, LOW );
}

// ------------------------------------------------------------------------------
void MMEmotor::moveAtSpeed(int speedVal) {
  
  // -- Positive speedVal means move forward;  negative speedVal means move in reverse
  if( speedVal>0 ) {
    forward(); 
  } else if ( speedVal<0 ) {
    backward();
  } else {
    brake();
  }
 
  // -- Limit _speed to range 0 <= _speed <= 255.  Don't use map() because it does
  //    not perform a range check 
   _speed = min( 255, abs(speedVal) );  // Guarantee positive value <= 255
  analogWrite( _PWMpin, _speed );
}

// ------------------------------------------------------------------------------
void MMEmotor::reverse() {
  if ( _direction>0 ) {
    backward();
  } else {
    forward();
  }
}

// ------------------------------------------------------------------------------
void MMEmotor::forward(int speedVal) {
  digitalWrite( _InPin1, HIGH );
  digitalWrite( _InPin2, LOW  ); 
  _direction = 1;
  _speed = min( 255, abs(speedVal) );
  analogWrite( _PWMpin, _speed );
}

// ------------------------------------------------------------------------------
void MMEmotor::forward() {
  digitalWrite( _InPin1, HIGH );
  digitalWrite( _InPin2, LOW  ); 
  _direction = 1;
}

// ------------------------------------------------------------------------------
void MMEmotor::backward(int speedVal) {
  digitalWrite( _InPin1, LOW );
  digitalWrite( _InPin2, HIGH  ); 
  _direction = -1;
  _speed = min( 255, abs(speedVal) );
  analogWrite( _PWMpin, _speed );
}

// ------------------------------------------------------------------------------
void MMEmotor::backward() {
  digitalWrite( _InPin1, LOW );
  digitalWrite( _InPin2, HIGH  ); 
  _direction = -1;
}

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ------------------------------------------------------------------------------
int MMEmotor::getDirection() {
  return(_direction);
}

// ------------------------------------------------------------------------------
int MMEmotor::getSpeed() {
  return(_speed);
}
