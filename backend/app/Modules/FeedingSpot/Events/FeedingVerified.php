<?php

namespace App\Modules\FeedingSpot\Events;

use App\Modules\FeedingSpot\Models\FeedingActivity;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class FeedingVerified
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly FeedingActivity $activity,
    ) {}
}
