#include <Arduino.h>
#include "hardware-components/OnboardLed.hpp"
#include "output/Result.hpp"
#include "structures/HashTable.hpp"
#include "config/config.hpp"

OnboardLed::OnboardLed(bool initialState) : Hardware(NO_PIN, NO_PIN, initialState) {};