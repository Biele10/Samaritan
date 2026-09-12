#pragma once
#include <Arduino.h>
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "hardware-components/Led.hpp"
#include "hardware-components/OnboardLed.hpp"
#include "hardware-components/UltrasonicSensor.hpp"


// When hardware is added, it MUST be configured here, this class instantiates all hardware classes for use throughout the program
// Adjust setupHardware function each time this is done and add getter methods to get objects from the class

class ArduinoController
{
    public:
        void setupHardware();
        ArduinoController(int redLedPin);
        Led& getRedLed();
        OnboardLed& getOnBoardLed();
        void process();
        //Result pendingResults; // stores results from functions that need sending back to server
    
    private:
        Led _redLed;
        OnboardLed _onboardLed;
};