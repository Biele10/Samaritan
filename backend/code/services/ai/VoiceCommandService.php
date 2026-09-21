<?php

namespace Samaritan\services\ai;

Class VoiceCommandService extends \Samaritan\services\Service
{
    public function sendVoiceCommand(string $command) : array
    {
        // INSERT LOGIC TO CALL OLLAMA WITH
        $result = "temp";
        error_log("COMMAND:\n");
        error_log($command);exit;
        if ($result['success'] !== true)
        {
            return ['success' => false, 'data' => ['message' => 'Failed to send command.']];
        }

        return ['success' => true, 'data' => ['message' => 'This worked!']];
    }
}