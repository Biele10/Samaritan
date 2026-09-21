#include <Arduino.h>
#include "hardware-components/UltrasonicSensor.hpp"
#include "config/config.hpp"
#include "structures/HashTable.hpp"
#include "controller/ArduinoController.hpp"
#include "output/Result.hpp"

/**
 * Constructor
 */
ArduinoController::ArduinoController(int redLedPin) : _redLed(redLedPin), _onboardLed() {}   // initialises all hardware being used and creates an object for each one

/**
 * Ran in setup function, sets up
 * all different pieces of hardware.
 */
void ArduinoController::setupHardware()
{
  pinMode(LED_BUILTIN, OUTPUT); //onboard LED
  pinMode(Config::RED_LED_PIN, OUTPUT);
}

Led& ArduinoController::getRedLed()
{
  return this->_redLed;
}

OnboardLed& ArduinoController::getOnBoardLed()
{
  return this->_onboardLed;
}