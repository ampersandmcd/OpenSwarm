#include <MMEmotor.h>

// Logic pins to control the motors: PWMA and PWMB must be pins capable of PWM output
// User needs to correctly wire these pins to corresponding contacts on TB6612 breakout
#define PWMA 5  // Motor A
#define AIN1 7
#define AIN2 6

#define STBY 8   // Standby pin of TB6612. Shared by both channels

#define PWMB 11   // Motor B
#define BIN1 9
#define BIN2 10

// -- Initialize a Motor object to control the motor on the paper roller
MMEmotor motorb  = MMEmotor(BIN1, BIN2, PWMB, STBY);
MMEmotor motora  = MMEmotor(AIN1, AIN2, PWMA, STBY);

void setup(){
  //
}

void loop() {
  delay(5000);
  turn(90);
  delay(1000);
  burst(100);
  delay(1000);
  turn(-90);
}

void turn(float deg) {
  float constant = 7;
  if (deg > 0) {
    //right turn
    motora.forward(50);
    motorb.backward(50);
    delay(int(deg * constant));
    fullstop();
  } else {
    //left turn
    motora.backward(50);
    motorb.forward(50);
    delay(abs(int(deg * constant)));
    fullstop();
  }
}

void burst(float velocity) {
  int pwr = int(velocity / 100.0 * 100);
  startup(pwr);
  delay(200);
  slowdown(pwr);
}

void startup(int sped){
  for(int i = 0; i < sped; i++){
    motora.backward(i);
    motorb.backward(i);
    delay(5);
  }
}
void slowdown(int sped){
  for(int i = sped; i >= 0; i--){
    motora.backward(i);
    motorb.backward(i);
    delay(5);
  }
  fullstop();
}
void drivefwd(int times, int speds){
  startup(speds);
  motora.backward(speds);
  motorb.backward(speds);
  delay(times);
  slowdown(speds);
}   
void driveback(int times, int speds){
  motora.backward(speds);
  motorb.backward(speds);
  slowdown(speds);
  delay(times);
} 
void turnleft(int times){
  motora.backward(50);
  motorb.forward(50);
  delay(times);
}
void turnright(int times){
  motora.forward(50);
  motorb.backward(50);
  delay(times);
}
void fullstop(){
  motora.brake();
  motorb.brake();
}
