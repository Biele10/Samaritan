<?php

namespace Samaritan\controllers\hardware\led;

Class LedController extends \Samaritan\controllers\hardware\HardwareController
{
    public function power(int $command) : \Samaritan\resources\Response
    {
        $ledService = new \Samaritan\services\hardware\led\LedService();
        $result = $ledService->power($command);

        $this->data = $result['data'];

        if ($result['success'] !== true)
        {
            return $this->Error();
        }

        return $this->Success();
    }

    public function powerRedLed() : \Samaritan\resources\Response
    {
        return $this->power(\Samaritan\arduino\Commands::RED_LED_POWER);
    }

    public function powerYesLed() : \Samaritan\resources\Response
    {
        return $this->power(\Samaritan\arduino\Commands::GREEN_LED_FLASH);
    }

    public function powerNoLed() : \Samaritan\resources\Response
    {
        return $this->power(\Samaritan\arduino\Commands::RED_LED_FLASH);
    }
}