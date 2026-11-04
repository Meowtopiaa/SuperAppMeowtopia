<?php

namespace App\Modules\Core\Events;

use App\Modules\Cat\Models\Cat;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CatStatusChanged
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public Cat $cat,
        public string $dimension,
        public string $fromValue,
        public string $toValue,
        public ?string $actorId = null,
        public ?string $reason = null
    ) {}
}

