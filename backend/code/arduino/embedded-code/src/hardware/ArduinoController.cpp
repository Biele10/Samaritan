#include <Arduino.h>
#include "hardware-components/UltrasonicSensor.hpp"
#include "config/config.hpp"
#include "structures/HashTable.hpp"
#include "controller/ArduinoController.hpp"
#include "output/Result.hpp"

/**
 * Constructor
 * Initialises all hardware being used and creates an object for each one
 */
ArduinoController::ArduinoController(const uint8_t redLedPin, const uint8_t hcDataPin, const uint8_t hcClockPin, const uint8_t hcLatchPin, const uint8_t hcMaxIndex)
: _redLed(redLedPin), _onboardLed(), _hc(hcDataPin, hcClockPin, hcLatchPin, hcMaxIndex)
{
  // adds all hardware to array
  this->_hardwareArray.addByPointer(&this->_redLed);
  this->_hardwareArray.addByPointer(&this->_onboardLed);
  this->_hardwareArray.addByPointer(&this->_hc);
}

/**
 * Ran in setup function, sets up
 * all different pieces of hardware.
 */
void ArduinoController::setupHardware()
{
  pinMode(LED_BUILTIN, OUTPUT); //onboard LED
  pinMode(Config::RED_LED_PIN, OUTPUT);
  pinMode(Config::HC_DATA_PIN, OUTPUT);
  pinMode(Config::HC_CLOCK_PIN, OUTPUT);
  pinMode(Config::HC_LATCH_PIN, OUTPUT);
}


Led& ArduinoController::getRedLed()
{
  return this->_redLed;
}

OnboardLed& ArduinoController::getOnBoardLed()
{
  return this->_onboardLed;
}

HC& ArduinoController::getHC()
{
  return this->_hc;
}

void ArduinoController::process()
{
  // add funcs that need to run constantly
}

/**
 * Runs update loop on all connected hardware.
 * Detects state changes in object classes
 * and updates hardware accordingly.
 */
void ArduinoController::update()
{
  for (Hardware* hardware : this->_hardwareArray)
  {
    if (hardware->getDirty())
    {
      hardware->update();
      hardware->setDirty(false);
    }
  }
}