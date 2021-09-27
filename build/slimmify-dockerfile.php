<?php
declare(strict_types=1);

$dockerfile = file(__DIR__.'/../dist/images/essentails/latest/Dockerfile');

echo $replaceCount = 0;
foreach ($dockerfile as $line => $lineContent) {
    if ($line === 1) {
        continue;
    }
    if (substr($lineContent, 0, 4) === 'RUN ') {
        $lineBefore = getNumberBefore($dockerfile, $line);
        if ($lineBefore === null) {
            continue;
        }

        echo substr($dockerfile[$lineBefore], 0, 3)."\n";
        if (substr($dockerfile[$lineBefore], 0, 3) === '&& ' ||substr($dockerfile[$lineBefore], 0, 4) === 'RUN ') {
            echo $line.'->'.$lineBefore."\n";
            $dockerfile[$line] = ' && '.substr($lineContent, 4);
            $replaceCount++;
        }
    }
}

echo $replaceCount.' ersetzt';

function getNumberBefore(array $content, $currentLine): ?int
{
    for ($i = $currentLine-1; $i !== 0; $i--) {
        $lineContent = trim($content[$i]);
        if ($content !== '' && substr($lineContent, 0, 1) !== '#' && substr($lineContent, 0, 1) !== '//') {
            return $i;
        }
    }

    return null;
}