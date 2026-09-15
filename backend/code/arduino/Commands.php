<?php

namespace Samaritan\arduino;

// This class defines the binary command associated with each command in the arduino

final class Commands
{
    // Commands have an ID which the arduino associates with a function

    // Each parameter costs 2 bytes, using uint_16t
    public const RED_LED_POWER = 0x0003;
    public const ONBOARD_LED_POWER = 0x0004;
    public const RED_LED_FLASH = 0x0005;
    public const GREEN_LED_FLASH = 0x0006;

}