<?php

namespace Samaritan\routes\hardware\led;
use Samaritan\controllers\hardware\led\LedController;

$r->addRoute(
    'PUT',
    '/hardware/redLed/power',
    [LedController::class, 'powerRedLed']
);

$r->addRoute(
    'PUT',
    '/hardware/yesLed/power',
    [LedController::class, 'powerYesLed']
);

$r->addRoute(
    'PUT',
    '/hardware/noLed/power',
    [LedController::class, 'powerNoLed']
);