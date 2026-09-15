<?php

namespace Samaritan\routes\ai;
use Samaritan\controllers\ai\VoiceCommandController;

$r->addRoute(
    'POST',
    '/ai/voice-command',
    [VoiceCommandController::class, 'sendVoiceCommand']
);