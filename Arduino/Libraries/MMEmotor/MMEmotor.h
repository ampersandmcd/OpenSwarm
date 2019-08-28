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


#ifndef MMEmotor_h

#define MMEmotor_h
#include "Arduino.h"
#include "math.h"

class MMEmotor {

	public:
		MMEmotor( int In1, int In2, int PWMpin, int SBpin);

		void begin();    //  Require this?
		void brake();
		void off();
		void moveAtSpeed(int speedVal);
		void forward(int speedVal);
		void forward();
		void backward(int speedVal);
		void backward();
		void reverse();
		void standby();

		int getSpeed();
		int getDirection();

	private:
		int _InPin1;
		int _InPin2;
		int _PWMpin;
		int _SBYpin;

		int _direction;    //  0 for unset/brake/off, +1 for forward, -1 for reverse
		int _speed;
};

#endif


