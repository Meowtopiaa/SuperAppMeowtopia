<?php

namespace App\Modules\Core\Services;

use App\Models\User;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use InvalidArgumentException;

class MediaService
{
    /**
     * Store uploaded file securely
     */
    public function store(UploadedFile $file, string $purpose, User $owner): array
    {
        $allowedPurposes = ['avatar', 'feeding_proof', 'adoption_evidence', 'incident_media', 'cat_photo'];
        if (!in_array($purpose, $allowedPurposes, true)) {
            throw new InvalidArgumentException("Invalid media purpose '{$purpose}'.");
        }

        // 5MB limit
        if ($file->getSize() > 5 * 1024 * 1024) {
            throw new InvalidArgumentException("Media file size exceeds the 5MB limit.");
        }

        $sha256 = hash_file('sha256', $file->getRealPath());
        $disk = config('filesystems.default', 'local');
        $ext = $file->getClientOriginalExtension() ?: 'jpg';
        $fileName = (string) Str::ulid() . '.' . $ext;
        $path = $file->storeAs('media/' . $purpose, $fileName, $disk);

        $visibility = in_array($purpose, ['avatar', 'cat_photo'], true) ? 'public' : 'private';
        $mediaId = (string) Str::ulid();

        DB::table('media_files')->insert([
            'id' => $mediaId,
            'owner_id' => $owner->id,
            'disk' => $disk,
            'path' => $path,
            'mime' => $file->getMimeType() ?: 'application/octet-stream',
            'size_bytes' => $file->getSize(),
            'sha256' => $sha256,
            'purpose' => $purpose,
            'visibility' => $visibility,
            'captured_at' => now(),
            'retention_until' => now()->addDays(180),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return [
            'id' => $mediaId,
            'url' => $this->getUrl($mediaId),
            'purpose' => $purpose,
            'size_bytes' => $file->getSize(),
        ];
    }

    /**
     * Get temporary signed URL (10 minutes) or public URL
     */
    public function getUrl(string $mediaId): ?string
    {
        $media = DB::table('media_files')->where('id', $mediaId)->first();
        if (!$media) {
            return null;
        }

        $disk = Storage::disk($media->disk);

        if ($media->visibility === 'public') {
            return $disk->url($media->path);
        }

        // Temporary signed URL for 10 minutes
        return $disk->temporaryUrl($media->path, now()->addMinutes(10));
    }
}

