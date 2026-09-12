#pragma once
#include "Arduino.h"

size_t calcFreeMemory();
bool isEnoughMemory(const size_t& bytes);