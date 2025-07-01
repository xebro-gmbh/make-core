#!/usr/bin/env php
<?php

declare(strict_types=1);

const SEARCH_FIRST = 0;
const SEARCH_SECOND = 1;
const SEARCH_MATCHED = 2;

$destinationFile = $argv[1];
$srcFile = $argv[2];
$newPattern = $argv[3] ?? '## ----- %s ------';

$handle = fopen($destinationFile, 'c+');
if (!$handle) {
    exit('Could not open file');
}

$mode = SEARCH_FIRST;
$newContent = '';
$lastLine = '';

while (($line = fgets($handle)) !== false) {
    $lineDelimiter = sprintf($newPattern, $srcFile);

    switch ($mode) {
        case SEARCH_FIRST:
            if ($lineDelimiter === trim($line)) {
                $mode = SEARCH_SECOND;
                break;
            }

            if ('' === trim($line) && trim($line) === $lastLine) {
                break;
            }
            $newContent .= $line;
            $lastLine = trim($line);
            break;

        case SEARCH_SECOND:
            if ($lineDelimiter === trim($line)) {
                $mode = SEARCH_MATCHED;
                $newContent .= printContent($srcFile, $newPattern);
            }
            break;

        case SEARCH_MATCHED:
            if ('' === trim($line) && trim($line) === $lastLine) {
                break;
            }

            $newContent .= $line;
            $lastLine = trim($line);
    }
}

if (SEARCH_FIRST === $mode) {
    $newContent .= printContent($srcFile, $newPattern);
}

fclose($handle);

file_put_contents($destinationFile, $newContent);

function printContent(string $file, $pattern)
{
    $text = "\n" . sprintf($pattern, $file) . "\n";

    $command = "envsubst <" . $file ;
    $text .= trim(shell_exec($command));

    $text .= "\n" . sprintf($pattern, $file);
    $text .= "\n\n";

    return $text;
}
