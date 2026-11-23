<?php

namespace App\Modules\Cat\Events;

use App\Modules\Cat\Models\Cat;
use App\Modules\Cat\Models\CatQrToken;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class CatQrRegenerated
{
    use Dispatchable, SerializesModels;

    public function __construct(
        public readonly Cat $cat,
        public readonly CatQrToken $newToken,
        public readonly ?string $actorId = null,
        public readonly ?string $reason = null,
    ) {}
}

