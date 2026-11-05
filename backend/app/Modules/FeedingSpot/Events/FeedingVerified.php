<?php

namespace App\Modules\FeedingSpot\Events;

use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class FeedingVerified
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public string $activityId,
        public string $userId,
        public string $spotId,
        public ?string $catId = null
    ) {
    }
}

