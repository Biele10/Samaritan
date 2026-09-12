#include "utilities/memory.hpp"
#include "Arduino.h"

// this class contains utility functions in relation to memory, this can be used across the framework in order to deduce whether space can be allocated or not
extern int __heap_start, *__brkval; // gives the start of the heap and the point to where it ends

// returns size of 
size_t calcFreeMemory()
{
    int v; // gets address at top of stack, dont care about value just need address num
    return ((size_t)&v - (__brkval == 0 ? (size_t) &__heap_start : (size_t)__brkval)); // subtract top of stack - bottom of heap, tells us how much free space is left
}

bool isEnoughMemory(const size_t& bytes)
{
    return (calcFreeMemory() >= bytes);
}