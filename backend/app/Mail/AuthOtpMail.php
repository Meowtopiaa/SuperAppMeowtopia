<?php

namespace App\Mail;

use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class AuthOtpMail extends Mailable
{
    use Queueable, SerializesModels;

    public function __construct(
        public readonly string $otp,
        public readonly string $recipientName,
    ) {}

    public function envelope(): Envelope
    {
        return new Envelope(subject: 'Kode keamanan Meowtopia');
    }

    public function content(): Content
    {
        return new Content(
            view: 'emails.auth-otp',
            text: 'emails.auth-otp-text',
        );
    }

    public function attachments(): array
    {
        return [];
    }
}
