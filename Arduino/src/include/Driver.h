#include "MMEmotor.h"

class Driver
{
  public:
    MMEmotor& MotorA;
    MMEmotor& MotorB;

    Driver(MMEmotor& a, MMEmotor& b) : MotorA(a), MotorB(b) {};

    void FullStop()
    {
      MotorA.brake();
      MotorB.brake();
    }

    void Turn(float deg) 
    {
      float constant = 7;
      if (deg > 0) {
        // left Turn (CCW = +)
        MotorA.backward(50);
        MotorB.forward(50);
        delay(abs(int(deg * constant)));
        FullStop();
      } else {
        // right Turn (CW = -)
        MotorA.forward(50);
        MotorB.backward(50);
        delay(abs(int(deg * constant)));
        FullStop();
      }
    }

    void Startup(int sped)
    {
      for(int i = 0; i < sped; i++){
        MotorA.backward(i);
        MotorB.backward(i);
        delay(5);
      }
    }

    void Slowdown(int sped)
    {
      for(int i = sped; i >= 0; i--){
        MotorA.backward(i);
        MotorB.backward(i);
        delay(5);
      }
      FullStop();
    }

    void Burst(float velocity) 
    {
      int pwr = int(velocity);
      Startup(pwr);
      Slowdown(pwr);
    }

    void Drive(float ang, float velocity) 
    {
      Turn(ang);
      Burst(velocity);
    }
};
