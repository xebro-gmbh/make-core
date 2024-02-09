#!/usr/bin/env php
<?php

$destinationFile = $argv[1];
$srcFile = $argv[2];
$newPattern = $argv[3] ?? '## ----- %s ------';

$handle = fopen($destinationFile, 'c+');
if (!$handle) {
    exit('Could not open file');
}

$mode = 'search_first';
$newContent = '';
$lastLine = '';


while (($line = fgets($handle)) !== false) {
    $lineDelimiter = sprintf($newPattern, $srcFile);

    switch ($mode) {
        case 'search_first':
            if ($lineDelimiter === trim($line)) {
                $mode = 'search_second';
                break;
            }

            if ('' === trim($line) && trim($line) === $lastLine) {
                break;
            }
            $newContent .= $line;
            $lastLine = trim($line);
            break;

        case 'search_second':
            if ($lineDelimiter === trim($line)) {
                $mode = 'matched';
                $newContent .= printContent($srcFile, $newPattern);
            }
            break;

        case 'matched':
            if ('' === trim($line) && trim($line) === $lastLine) {
                break;
            }

            $newContent .= $line;
            $lastLine = trim($line);
    }
}

if ('search_first' === $mode) {
    $newContent .= printContent($srcFile, $newPattern);
}

fclose($handle);

file_put_contents($destinationFile, $newContent);

function printContent(string $file, $pattern)
{
    $text = "\n".sprintf($pattern, $file)."\n";
    ob_start();
    include $file;
    $text .= trim(ob_get_contents());
    ob_get_clean();
    $text .= "\n".sprintf($pattern, $file);
    $text .="\n\n";

    return $text;
}
