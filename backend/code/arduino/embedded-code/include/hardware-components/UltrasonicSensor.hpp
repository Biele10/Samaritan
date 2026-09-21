#pragma once
#include "structures/HashTable.hpp"
#include "output/Result.hpp"
#include "HCSR04.h"
#include "hardware-components/Hardware.hpp"

enum MovementResult
{
    MOVEMENT,
    NO_MOVEMENT,
    WAITING
};

class UltrasonicSensor : public Hardware
{
    public:
        UltrasonicSensor(int trigPin, int echoPin);
        size_t getDistance();
        bool doEcho();
        MovementResult movementCheck(size_t avgDistance);     // average distance is used to determine what to measure against to see if movement has been detected
        size_t getAvgDistance();

    private:
        HCSR04 us;
        unsigned long lastRead;     // the last time the ultrasonic sensor was read from, used to determine whether to send a signal or not
        size_t MINIMUM_ECHO_WAIT = 500;     // minimum waiting time before starting any echo based operation
        size_t READS_FOR_AVG_DIST_COUNT = 5;      // number that determines how many echo reads should be done in order to calculate an average distance
        size_t MIN_DIST_BOUNDARY = 0;
        size_t MAX_DIST_BOUNDARY = 1000;
        size_t MOVEMENT_THRESHOLD = 5;
};