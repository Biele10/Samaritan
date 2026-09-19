#pragma once
#include <Arduino.h>
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Hardware.hpp"
#include "hardware-components/Led.hpp"
#include "hardware-components/OnboardLed.hpp"
#include "hardware-components/UltrasonicSensor.hpp"
#include "hardware-components/HC.hpp"
#include "structures/Array.hpp"


// When hardware is added, it MUST be configured here, this class instantiates all hardware classes for use throughout the program
// Adjust setupHardware function each time this is done and add getter methods to get objects from the class

class ArduinoController
{
    public:
        void setupHardware();
        ArduinoController(const uint8_t redLedPin, const uint8_t hcDataPin, const uint8_t hcClockPin, const uint8_t hcLatchPin, const uint8_t hcMaxIndex);
        Led& getRedLed();
        OnboardLed& getOnBoardLed();
        HC& getHC();
        void process();
        void update();
        //Result pendingResults; // stores results from functions that need sending back to server
    
    private:
        Led _redLed;
        OnboardLed _onboardLed;
        HC _hc;
        Array<Hardware> _hardwareArray;
};