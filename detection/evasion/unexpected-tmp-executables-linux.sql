-- Find unexpected executables in temp directories, often used by malware droppers
--
-- false positives:
--   * developers building code out of /tmp
--
-- tags: persistent
-- platform: linux
SELECT DISTINCT
  file.path,
  uid,
  gid,
  mode,
  REGEX_MATCH (file.filename, '.*\.(.*?)$', 1) AS extension,
  file.btime,
  file.ctime,
  file.mtime,
  file.size,
  hash.sha256,
  magic.data
FROM
  file
  LEFT JOIN hash on file.path = hash.path
  LEFT JOIN magic ON file.path = magic.path
WHERE -- Optimization: don't join things until we have a whittled down list of files
  file.path IN (
    SELECT DISTINCT
      path
    FROM
      file
    WHERE
      (
        file.directory = '/tmp'
        OR file.directory LIKE '/tmp/%'
        OR file.directory LIKE '/tmp/%/%'
        OR file.directory LIKE '/tmp/%/.%'
        OR file.directory LIKE '/tmp/.%'
        OR file.directory LIKE '/tmp/.%/%'
        or file.directory LIKE '/tmp/.%/.%'
      ) -- Prevent weird recursion
      AND NOT file.directory LIKE '%/../%'
      AND NOT file.directory LIKE '%/./%' -- Exclude very temporary files
      AND NOT (strftime('%s', 'now') - ctime) < 60 -- Only executable files
      AND file.type = 'regular'
      AND (
        file.mode LIKE '%7%'
        or file.mode LIKE '%5%'
        or file.mode LIKE '%1%'
      )
      AND NOT (
        uid > 500
        AND (
          file.path LIKE '%/go-build%'
          OR file.directory LIKE '/tmp/%/out'
          OR file.path LIKE '%/bin/%'
          OR file.path LIKE '%/checkout/%'
          OR file.path LIKE '%/ci/%'
          OR file.path LIKE '%/Rakefile'
          OR file.path LIKE '%/debug/%'
          OR file.path LIKE '%/dist/%'
          OR file.path LIKE '%/flow/%.npmzS_cacachezStmpzSgit-clone%'
          OR file.path LIKE '%/git/%'
          OR file.path LIKE '%/github/%'
          OR file.path LIKE '%/go.%.sum'
          OR file.path LIKE "%/%/gradlew"
          OR file.path LIKE '%/guile-%/guile-%'
          OR file.path LIKE '%/melange-guest-%'
          OR file.path LIKE '%/ko/%'
          OR file.path LIKE '%/kots/%'
          OR file.path LIKE "%/lib/%.so"
          OR file.path LIKE "%/lib/%.so.%"
          OR file.path LIKE '%/pdf-tools/%'
          OR file.path LIKE '%-release%/%'
          OR file.path LIKE '%/site-packages/markupsafe/_speedups.cpython-%'
          OR file.path LIKE '%/src/%'
          OR file.path LIKE '%/target/%'
          OR file.path LIKE '%/terraformer/%'
          OR file.path LIKE '%/tmp/epdf%'
          OR file.path LIKE '/tmp/lima/%/out/%'
        )
      ) -- Nix
      AND NOT (
        file.directory LIKE '/tmp/tmp%'
        AND gid = 0
        AND uid > 300
        AND uid < 350
      ) -- Babel
      AND NOT (
        file.directory LIKE '/tmp/babel-%/sh-script-%'
        AND gid > 900
        AND uid = 1000
        AND size < 1024
      ) -- Random Testdata
      AND NOT (
        gid > 900
        AND uid = 1000
        AND (
          file.directory LIKE '/tmp/%/test'
          OR file.directory LIKE '/tmp/%/testdata'
        )
      ) -- Don't alert if the file is only on disk for a moment
      AND NOT (
        uid > 500
        AND file.path LIKE '/tmp/terraform_%/terraform'
      )
      AND NOT (
        file.path LIKE '/tmp/%compressed'
        AND size < 4000
        AND uid > 500
      ) -- Executables too small to even hold '#!/bin/sh\nuid'
      AND NOT (
        file.type = 'regular'
        AND size < 10
      ) -- Weird cert
      AND NOT (
        file.path LIKE '/tmp/tmp.%/ssl/default-fake-certificate.pem'
        AND file.size < 4096
      ) -- Binaries we might actually see legitimately
      AND NOT (
        file.path LIKE '/tmp/%'
        AND file.uid > 500
        AND (
          file.filename LIKE "%ctl"
          OR file.filename LIKE "%adm"
          OR file.filename LIKE "%-cli"
        )
      )
      AND NOT (
        file.directory LIKE "%/lib"
        OR file.directory LIKE "%/lib64"
        AND file.uid > 500
        AND (
          file.filename LIKE "%.so.%"
          OR file.filename LIKE "%.so"
        )
      )
  ) -- All checks with magic.data must first check for a lack of NULL value,
  -- otherwise you filter out platforms without magic.data.
  AND NOT (
    file.uid > 500
    AND magic.data IS NOT NULL
    AND (
      magic.data IN (
        "POSIX shell script, ASCII text executable",
        "JSON data"
      )
      OR magic.data LIKE "Unicode text%"
      OR magic.data LIKE "gzip compressed data%" -- Exotic platforms
      OR magic.data LIKE 'ELF 64-bit MSB pie executable, IBM S/390%'
      OR magic.data LIKE 'ELF 32-bit LSB pie executable, ARM, EABI5%'
    )
  )
  AND NOT (
    file.size < 50000
    AND file.uid > 500
    AND file.filename LIKE "%.%"
    AND extension IN (
      'adoc',
      'bat',
      'erb',
      'java',
      'js',
      'json',
      'log',
      'nib',
      'pem',
      'perl',
      'pl',
      'py',
      'rb',
      'script',
      'sh',
      'strings',
      'txt',
      'yaml',
      'yml'
    )
  )
