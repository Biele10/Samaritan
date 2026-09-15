<?php

namespace Samaritan\controllers\ai;

final Class VoiceCommandController extends \Samaritan\controllers\Controller
{
    public function sendVoiceCommand() : \Samaritan\resources\Response
    {
        $body = file_get_contents('php://input');
        $data = json_decode($body, true);
        
        // if (empty($data['command'])){}
        $command = $data['command']; // our json command to send to AI service

        $vcService = new \Samaritan\services\ai\VoiceCommandService();
        $result = $vcService->sendVoiceCommand($command);

        $this->data = $result['data'];

        if ($result['success'] !== true)
        {
            return $this->Error();
        }

        return $this->Success();
    }
}