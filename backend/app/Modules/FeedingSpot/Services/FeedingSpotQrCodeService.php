<?php

namespace App\Modules\FeedingSpot\Services;

use InvalidArgumentException;

/**
 * Generator QR Code Standar ISO/IEC 18004 untuk Modul Adopt Feeding Spot (MEOW-21, MEOW-28).
 * Menghasilkan matriks QR valid yang dapat dipindai oleh kamera smartphone (mobile_scanner, iOS/Android)
 * dalam format SVG maupun PNG tanpa ketergantungan layanan eksternal.
 */
class FeedingSpotQrCodeService
{
    /**
     * Tabel kapasitas 1-blok untuk Byte Mode:
     * [version, size, total_codewords, data_codewords, ec_codewords, ec_level_bits (00=M, 01=L)]
     */
    private const VERSION_SPECS = [
        // Version 1-M (21x21): max 14 bytes
        [1, 21, 26, 16, 10, 0b00],
        // Version 2-M (25x25): max 26 bytes
        [2, 25, 44, 28, 16, 0b00],
        // Version 3-M (29x29): max 42 bytes (ideal untuk MTP1.S.<32-char-token> = 39 bytes)
        [3, 29, 70, 44, 26, 0b00],
        // Version 3-L (29x29): max 53 bytes
        [3, 29, 70, 55, 15, 0b01],
        // Version 4-L (33x33): max 78 bytes
        [4, 33, 100, 80, 20, 0b01],
        // Version 5-L (37x37): max 106 bytes
        [5, 37, 134, 108, 26, 0b01],
    ];

    /**
     * Format payload resmi QR Spot sesuai PRD Bagian 2 & 10.2: MTP1.S.<token>
     */
    public function formatSpotPayload(string $qrToken): string
    {
        $clean = trim($qrToken);
        if (str_starts_with($clean, 'MTP1.S.')) {
            return $clean;
        }

        return 'MTP1.S.' . $clean;
    }

    /**
     * Bangun matriks boolean 2D (true = modul gelap/hitam, false = terang/putih) sesuai ISO/IEC 18004.
     *
     * @return array<int, array<int, bool>>
     */
    public function generateMatrix(string $payload): array
    {
        $bytes = array_values(unpack('C*', $payload));
        $len = count($bytes);

        if ($len === 0 || $len > 106) {
            throw new InvalidArgumentException('Panjang payload QR harus antara 1 hingga 106 byte.');
        }

        $spec = null;
        foreach (self::VERSION_SPECS as $candidate) {
            $maxPayloadBytes = $candidate[3] - 2; // 4-bit mode + 8-bit length = 12 bits (1.5 bytes -> max capacity - 2)
            if ($len <= $maxPayloadBytes) {
                $spec = $candidate;
                break;
            }
        }

        if ($spec === null) {
            $spec = self::VERSION_SPECS[count(self::VERSION_SPECS) - 1];
        }

        [$version, $size, $totalCodewords, $dataCodewords, $ecCodewords, $ecLevelBits] = $spec;

        $dataBytes = $this->encodeDataCodewords($bytes, $dataCodewords);
        $ecBytes = $this->computeReedSolomon($dataBytes, $ecCodewords);
        $allCodewords = array_merge($dataBytes, $ecBytes);

        $matrix = array_fill(0, $size, array_fill(0, $size, false));
        $isFunction = array_fill(0, $size, array_fill(0, $size, false));

        $this->placeFunctionPatterns($matrix, $isFunction, $version, $size);
        $this->placeCodewords($matrix, $isFunction, $allCodewords, $size);

        $bestMask = $this->selectBestMask($matrix, $isFunction, $size, $ecLevelBits);
        $this->applyMask($matrix, $isFunction, $size, $bestMask);
        $this->placeFormatBits($matrix, $isFunction, $size, $ecLevelBits, $bestMask);

        return $matrix;
    }

    /**
     * Render QR Code sebagai elemen SVG vektor dengan quiet zone standar (default 4 modul).
     */
    public function renderSvg(
        string $payload,
        int $sizePx = 240,
        int $marginModules = 4,
        string $darkColor = '#0F172A',
        string $lightColor = '#FFFFFF'
    ): string {
        $matrix = $this->generateMatrix($payload);
        $moduleCount = count($matrix);
        $totalModules = $moduleCount + ($marginModules * 2);

        $paths = [];
        for ($r = 0; $r < $moduleCount; $r++) {
            $y = $r + $marginModules;
            $runStart = null;
            for ($c = 0; $c <= $moduleCount; $c++) {
                $isDark = ($c < $moduleCount) && $matrix[$r][$c];
                if ($isDark && $runStart === null) {
                    $runStart = $c + $marginModules;
                } elseif (!$isDark && $runStart !== null) {
                    $w = ($c + $marginModules) - $runStart;
                    $paths[] = "M{$runStart},{$y}h{$w}v1h-{$w}z";
                    $runStart = null;
                }
            }
        }

        $pathData = implode('', $paths);
        $escapedPayload = htmlspecialchars($payload, ENT_QUOTES, 'UTF-8');

        return '<svg xmlns="http://www.w3.org/2000/svg" width="' . $sizePx . '" height="' . $sizePx . '" viewBox="0 0 ' . $totalModules . ' ' . $totalModules . '" shape-rendering="crispEdges" role="img" aria-label="QR Code ' . $escapedPayload . '">'
            . '<rect width="' . $totalModules . '" height="' . $totalModules . '" fill="' . $lightColor . '"/>'
            . '<path d="' . $pathData . '" fill="' . $darkColor . '"/>'
            . '</svg>';
    }

    /**
     * Render QR Code sebagai berkas biner PNG murni (tanpa membutuhkan ekstensi GD/Imagick).
     */
    public function renderPng(
        string $payload,
        int $scale = 10,
        int $marginModules = 4
    ): string {
        $matrix = $this->generateMatrix($payload);
        $moduleCount = count($matrix);
        $scale = max(4, min(32, $scale));
        $totalModules = $moduleCount + ($marginModules * 2);
        $imgSize = $totalModules * $scale;

        // Bangun scanlines grayscale 8-bit (filter byte 0x00 di awal setiap baris)
        $whiteRow = "\x00" . str_repeat("\xFF", $imgSize);
        $rawScanlines = '';

        for ($mRow = 0; $mRow < $totalModules; $mRow++) {
            $inBoundsRow = ($mRow >= $marginModules && $mRow < $marginModules + $moduleCount);
            if (!$inBoundsRow) {
                $rawScanlines .= str_repeat($whiteRow, $scale);
                continue;
            }

            $r = $mRow - $marginModules;
            $line = "\x00";
            for ($mCol = 0; $mCol < $totalModules; $mCol++) {
                $inBoundsCol = ($mCol >= $marginModules && $mCol < $marginModules + $moduleCount);
                $isDark = $inBoundsCol && $matrix[$r][$mCol - $marginModules];
                $line .= str_repeat($isDark ? "\x00" : "\xFF", $scale);
            }
            $rawScanlines .= str_repeat($line, $scale);
        }

        $ihdrData = pack('NNCCCCC', $imgSize, $imgSize, 8, 0, 0, 0, 0);
        $idatData = gzcompress($rawScanlines, 9);

        return "\x89PNG\r\n\x1a\n"
            . $this->pngChunk('IHDR', $ihdrData)
            . $this->pngChunk('IDAT', $idatData)
            . $this->pngChunk('IEND', '');
    }

    private function pngChunk(string $type, string $data): string
    {
        return pack('N', strlen($data))
            . $type
            . $data
            . pack('N', crc32($type . $data));
    }

    /**
     * @param  array<int, int>  $bytes
     * @return array<int, int>
     */
    private function encodeDataCodewords(array $bytes, int $dataCodewords): array
    {
        $bits = [];

        // Mode indicator Byte mode = 0100
        $this->appendBits($bits, 0b0100, 4);
        // Character count indicator (8 bits untuk Version 1..9)
        $this->appendBits($bits, count($bytes), 8);

        foreach ($bytes as $b) {
            $this->appendBits($bits, $b, 8);
        }

        $capacityBits = $dataCodewords * 8;
        $terminatorLen = min(4, $capacityBits - count($bits));
        if ($terminatorLen > 0) {
            $this->appendBits($bits, 0, $terminatorLen);
        }

        while (count($bits) % 8 !== 0) {
            $bits[] = 0;
        }

        $codewords = [];
        for ($i = 0, $n = count($bits); $i < $n; $i += 8) {
            $val = 0;
            for ($j = 0; $j < 8; $j++) {
                $val = ($val << 1) | $bits[$i + $j];
            }
            $codewords[] = $val;
        }

        $padBytes = [0xEC, 0x11];
        $padIdx = 0;
        while (count($codewords) < $dataCodewords) {
            $codewords[] = $padBytes[$padIdx % 2];
            $padIdx++;
        }

        return $codewords;
    }

    /**
     * @param  array<int, int>  $bits
     */
    private function appendBits(array &$bits, int $value, int $numBits): void
    {
        for ($i = $numBits - 1; $i >= 0; $i--) {
            $bits[] = ($value >> $i) & 1;
        }
    }

    /**
     * Hitung Reed-Solomon error correction codewords di GF(2^8) (polinom primitif 0x11D).
     *
     * @param  array<int, int>  $data
     * @return array<int, int>
     */
    private function computeReedSolomon(array $data, int $degree): array
    {
        $exp = array_fill(0, 512, 0);
        $log = array_fill(0, 256, 0);
        $x = 1;
        for ($i = 0; $i < 255; $i++) {
            $exp[$i] = $x;
            $exp[$i + 255] = $x;
            $log[$x] = $i;
            $x <<= 1;
            if ($x & 0x100) {
                $x ^= 0x11D;
            }
        }

        $gfMul = static function (int $a, int $b) use ($exp, $log): int {
            if ($a === 0 || $b === 0) {
                return 0;
            }
            return $exp[$log[$a] + $log[$b]];
        };

        // Bangun polinomial generator g(x) = (x - alpha^0)(x - alpha^1)...(x - alpha^(degree-1))
        $gen = [1];
        for ($i = 0; $i < $degree; $i++) {
            $root = $exp[$i];
            $nextGen = array_fill(0, count($gen) + 1, 0);
            for ($j = 0, $n = count($gen); $j < $n; $j++) {
                $nextGen[$j] ^= $gen[$j];
                $nextGen[$j + 1] ^= $gfMul($gen[$j], $root);
            }
            $gen = $nextGen;
        }

        $result = array_fill(0, $degree, 0);
        foreach ($data as $byte) {
            $factor = $byte ^ array_shift($result);
            $result[] = 0;
            if ($factor !== 0) {
                for ($j = 0; $j < $degree; $j++) {
                    $result[$j] ^= $gfMul($gen[$j + 1], $factor);
                }
            }
        }

        return $result;
    }

    private function placeFunctionPatterns(array &$matrix, array &$isFunction, int $version, int $size): void
    {
        // Finder patterns + separators di 3 sudut
        $this->placeFinderPattern($matrix, $isFunction, 0, 0, $size);
        $this->placeFinderPattern($matrix, $isFunction, 0, $size - 7, $size);
        $this->placeFinderPattern($matrix, $isFunction, $size - 7, 0, $size);

        // Alignment pattern untuk Version >= 2
        if ($version >= 2) {
            $alignCenter = $size - 7;
            for ($dr = -2; $dr <= 2; $dr++) {
                for ($dc = -2; $dc <= 2; $dc++) {
                    $r = $alignCenter + $dr;
                    $c = $alignCenter + $dc;
                    $dist = max(abs($dr), abs($dc));
                    $matrix[$r][$c] = ($dist !== 1);
                    $isFunction[$r][$c] = true;
                }
            }
        }

        // Timing patterns (baris 6 dan kolom 6)
        for ($i = 8; $i < $size - 8; $i++) {
            $dark = ($i % 2 === 0);
            if (!$isFunction[6][$i]) {
                $matrix[6][$i] = $dark;
                $isFunction[6][$i] = true;
            }
            if (!$isFunction[$i][6]) {
                $matrix[$i][6] = $dark;
                $isFunction[$i][6] = true;
            }
        }

        // Dark module di (4*V + 9, 8) = (size - 8, 8)
        $matrix[$size - 8][8] = true;
        $isFunction[$size - 8][8] = true;

        // Reservasi area Format Information
        for ($i = 0; $i <= 8; $i++) {
            if ($i !== 6) {
                $isFunction[8][$i] = true;
                $isFunction[$i][8] = true;
            }
        }
        for ($i = 0; $i < 8; $i++) {
            $isFunction[8][$size - 1 - $i] = true;
        }
        for ($i = 0; $i < 7; $i++) {
            $isFunction[$size - 7 + $i][8] = true;
        }
    }

    private function placeFinderPattern(array &$matrix, array &$isFunction, int $top, int $left, int $size): void
    {
        for ($dr = -1; $dr <= 7; $dr++) {
            for ($dc = -1; $dc <= 7; $dc++) {
                $r = $top + $dr;
                $c = $left + $dc;
                if ($r < 0 || $r >= $size || $c < 0 || $c >= $size) {
                    continue;
                }

                $inOuter = ($dr >= 0 && $dr <= 6 && $dc >= 0 && $dc <= 6);
                if (!$inOuter) {
                    $matrix[$r][$c] = false;
                } else {
                    $dist = max(abs($dr - 3), abs($dc - 3));
                    $matrix[$r][$c] = ($dist !== 2);
                }
                $isFunction[$r][$c] = true;
            }
        }
    }

    /**
     * @param  array<int, int>  $codewords
     */
    private function placeCodewords(array &$matrix, array &$isFunction, array $codewords, int $size): void
    {
        $bits = [];
        foreach ($codewords as $cw) {
            for ($i = 7; $i >= 0; $i--) {
                $bits[] = (($cw >> $i) & 1) === 1;
            }
        }

        $bitIdx = 0;
        $totalBits = count($bits);
        $upward = true;

        for ($right = $size - 1; $right >= 1; $right -= 2) {
            if ($right === 6) {
                $right = 5;
            }

            for ($step = 0; $step < $size; $step++) {
                $r = $upward ? ($size - 1 - $step) : $step;
                for ($j = 0; $j < 2; $j++) {
                    $c = $right - $j;
                    if (!$isFunction[$r][$c]) {
                        $matrix[$r][$c] = $bitIdx < $totalBits ? $bits[$bitIdx] : false;
                        $bitIdx++;
                    }
                }
            }
            $upward = !$upward;
        }
    }

    private function maskBit(int $mask, int $r, int $c): bool
    {
        return match ($mask) {
            0 => (($r + $c) % 2) === 0,
            1 => ($r % 2) === 0,
            2 => ($c % 3) === 0,
            3 => (($r + $c) % 3) === 0,
            4 => ((intdiv($r, 2) + intdiv($c, 3)) % 2) === 0,
            5 => ((($r * $c) % 2) + (($r * $c) % 3)) === 0,
            6 => (((($r * $c) % 2) + (($r * $c) % 3)) % 2) === 0,
            7 => (((($r + $c) % 2) + (($r * $c) % 3)) % 2) === 0,
            default => false,
        };
    }

    private function applyMask(array &$matrix, array $isFunction, int $size, int $mask): void
    {
        for ($r = 0; $r < $size; $r++) {
            for ($c = 0; $c < $size; $c++) {
                if (!$isFunction[$r][$c] && $this->maskBit($mask, $r, $c)) {
                    $matrix[$r][$c] = !$matrix[$r][$c];
                }
            }
        }
    }

    private function selectBestMask(array $matrix, array $isFunction, int $size, int $ecLevelBits): int
    {
        $bestMask = 0;
        $minPenalty = PHP_INT_MAX;

        for ($mask = 0; $mask < 8; $mask++) {
            $candidate = $matrix;
            $fnCopy = $isFunction;
            $this->applyMask($candidate, $fnCopy, $size, $mask);
            $this->placeFormatBits($candidate, $fnCopy, $size, $ecLevelBits, $mask);

            $penalty = $this->calculatePenalty($candidate, $size);
            if ($penalty < $minPenalty) {
                $minPenalty = $penalty;
                $bestMask = $mask;
            }
        }

        return $bestMask;
    }

    private function calculatePenalty(array $matrix, int $size): int
    {
        $penalty = 0;

        // Aturan 1: 5+ modul berurutan berwarna sama pada baris/kolom
        for ($i = 0; $i < $size; $i++) {
            $runRow = 1;
            $runCol = 1;
            for ($j = 1; $j < $size; $j++) {
                if ($matrix[$i][$j] === $matrix[$i][$j - 1]) {
                    $runRow++;
                    if ($runRow === 5) {
                        $penalty += 3;
                    } elseif ($runRow > 5) {
                        $penalty += 1;
                    }
                } else {
                    $runRow = 1;
                }

                if ($matrix[$j][$i] === $matrix[$j - 1][$i]) {
                    $runCol++;
                    if ($runCol === 5) {
                        $penalty += 3;
                    } elseif ($runCol > 5) {
                        $penalty += 1;
                    }
                } else {
                    $runCol = 1;
                }
            }
        }

        // Aturan 2: Blok 2x2 berwarna sama
        for ($r = 0; $r < $size - 1; $r++) {
            for ($c = 0; $c < $size - 1; $c++) {
                $v = $matrix[$r][$c];
                if ($v === $matrix[$r][$c + 1] && $v === $matrix[$r + 1][$c] && $v === $matrix[$r + 1][$c + 1]) {
                    $penalty += 3;
                }
            }
        }

        return $penalty;
    }

    private function placeFormatBits(array &$matrix, array &$isFunction, int $size, int $ecLevelBits, int $mask): void
    {
        $data = (($ecLevelBits & 0b11) << 3) | ($mask & 0b111);
        $rem = $data << 10;
        for ($i = 14; $i >= 10; $i--) {
            if ((($rem >> $i) & 1) !== 0) {
                $rem ^= (0x537 << ($i - 10));
            }
        }
        $bits = (($data << 10) | $rem) ^ 0x5412;

        // Salinan 1: sekitar sudut kiri atas
        for ($i = 0; $i <= 5; $i++) {
            $matrix[$i][8] = (($bits >> $i) & 1) === 1;
        }
        $matrix[7][8] = (($bits >> 6) & 1) === 1;
        $matrix[8][8] = (($bits >> 7) & 1) === 1;
        $matrix[8][7] = (($bits >> 8) & 1) === 1;
        for ($i = 9; $i < 15; $i++) {
            $matrix[8][14 - $i] = (($bits >> $i) & 1) === 1;
        }

        // Salinan 2: sudut kanan atas & kiri bawah
        for ($i = 0; $i < 8; $i++) {
            $matrix[8][$size - 1 - $i] = (($bits >> $i) & 1) === 1;
        }
        for ($i = 8; $i < 15; $i++) {
            $matrix[$size - 15 + $i][8] = (($bits >> $i) & 1) === 1;
        }
    }

    /**
     * Dekode matriks QR Code kembali menjadi string payload asli (untuk verifikasi otomatis).
     *
     * @param  array<int, array<int, bool>>  $matrix
     */
    public function decodeMatrix(array $matrix): string
    {
        $size = count($matrix);
        $version = intdiv($size - 17, 4);

        // Baca 15-bit format info dari Salinan 1
        $bits = 0;
        for ($i = 0; $i <= 5; $i++) {
            if ($matrix[$i][8]) {
                $bits |= (1 << $i);
            }
        }
        if ($matrix[7][8]) {
            $bits |= (1 << 6);
        }
        if ($matrix[8][8]) {
            $bits |= (1 << 7);
        }
        if ($matrix[8][7]) {
            $bits |= (1 << 8);
        }
        for ($i = 9; $i < 15; $i++) {
            if ($matrix[8][14 - $i]) {
                $bits |= (1 << $i);
            }
        }

        $unmaskedFormat = $bits ^ 0x5412;
        $dataFormat = $unmaskedFormat >> 10;
        $mask = $dataFormat & 0b111;

        // Tandai function patterns agar bisa di-unmask dan dibaca
        $dummy = array_fill(0, $size, array_fill(0, $size, false));
        $isFunction = array_fill(0, $size, array_fill(0, $size, false));
        $this->placeFunctionPatterns($dummy, $isFunction, $version, $size);

        $unmasked = $matrix;
        $this->applyMask($unmasked, $isFunction, $size, $mask);

        // Baca bit stream secara zig-zag
        $rawBits = [];
        $upward = true;
        for ($right = $size - 1; $right >= 1; $right -= 2) {
            if ($right === 6) {
                $right = 5;
            }
            for ($step = 0; $step < $size; $step++) {
                $r = $upward ? ($size - 1 - $step) : $step;
                for ($j = 0; $j < 2; $j++) {
                    $c = $right - $j;
                    if (!$isFunction[$r][$c]) {
                        $rawBits[] = $unmasked[$r][$c] ? 1 : 0;
                    }
                }
            }
            $upward = !$upward;
        }

        // 4 bit pertama = mode (0100 = Byte Mode)
        $mode = ($rawBits[0] << 3) | ($rawBits[1] << 2) | ($rawBits[2] << 1) | $rawBits[3];
        if ($mode !== 0b0100) {
            throw new InvalidArgumentException("Mode QR bukan Byte Mode: {$mode}");
        }

        // 8 bit berikutnya = panjang karakter
        $length = 0;
        for ($i = 0; $i < 8; $i++) {
            $length = ($length << 1) | $rawBits[4 + $i];
        }

        $chars = '';
        $offset = 12;
        for ($b = 0; $b < $length; $b++) {
            $val = 0;
            for ($i = 0; $i < 8; $i++) {
                $val = ($val << 1) | $rawBits[$offset + $i];
            }
            $chars .= chr($val);
            $offset += 8;
        }

        return $chars;
    }
}
