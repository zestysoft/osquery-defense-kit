-- Surface ISO/DMG disk images that were downloaded from unexpected places
--
-- references:
--   * https://attack.mitre.org/techniques/T1566/001/ (Phishing: Spearphishing Attachment)
--   * https://attack.mitre.org/techniques/T1204/002/ (User Execution: Malicious File)
--   * https://unit42.paloaltonetworks.com/chromeloader-malware/
--
-- false positives:
--   * disk images downloaded from a location not in the exception list
--
-- platform: darwin
-- tags: persistent filesystem spotlight
SELECT
  file.path,
  file.size,
  datetime(file.btime, 'unixepoch') AS file_created,
  magic.data,
  hash.sha256,
  signature.identifier,
  signature.authority,
  ea.value AS url,
  REGEX_MATCH (ea.value, '/[\w_-]+\.([\w\._-]+)[:/]', 1) AS domain,
  REGEX_MATCH (ea.value, '/([\w_-]+\.[\w\._-]+)[:/]', 1) AS host
FROM
  mdfind
  LEFT JOIN file ON mdfind.path = file.path
  LEFT JOIN hash ON mdfind.path = hash.path
  LEFT JOIN extended_attributes ea ON mdfind.path = ea.path
  LEFT JOIN magic ON mdfind.path = magic.path
  LEFT JOIN signature ON mdfind.path = signature.path
WHERE
  (
    mdfind.query = "kMDItemWhereFroms != '' && kMDItemFSName == '*.iso'"
    OR mdfind.query = "kMDItemWhereFroms != '' && kMDItemFSName == '*.dmg'"
    OR mdfind.query = "kMDItemWhereFroms != '' && kMDItemFSName == '*.pkg'"
  )
  AND ea.key = 'where_from'
  AND file.btime > (strftime('%s', 'now') -86400)
  AND domain NOT IN (
    'adobe.com',
    'akmedia.digidesign.com',
    'alfredapp.com',
    'android.com',
    'apple.com',
    'arc.net',
    'balena.io',
    'balsamiq.com',
    'brave.com',
    'canon.co.uk',
    'cdn.mozilla.net',
    'charlesproxy.com',
    'cloudfront.net',
    'cron.com',
    'csclub.uwaterloo.ca',
    'c-wss.com',
    'digidesign.com',
    'discordapp.net',
    'discord.com',
    'docker.com',
    'dogado.de',
    'download.prss.microsoft.com',
    'duckduckgo.com',
    'eclipse.org',
    'epson.com',
    'fcix.net',
    'gaomon.net',
    'kagi.com',
    'getutm.app',
    'gimp.org',
    'github.io',
    'githubusercontent.com',
    'google.ca',
    'grammarly.com',
    'integodownload.com',
    'irccloud.com',
    'jetbrains.com',
    'libreoffice.org',
    'logitech.com',
    'loom.com',
    'macbartender.com',
    'microsoft.com',
    'minecraft.net',
    'mirrorservice.org',
    'mojang.com',
    'mozilla.org',
    'mysql.com',
    'notion.so',
    'notion-static.com',
    'ocf.berkeley.edu',
    'oobesaas.adobe.com',
    'oracle.com',
    'osuosl.org',
    'pqrs.org',
    'prusa3d.com',
    'remarkable.com',
    'securew2.com',
    'signal.org',
    'skype.com',
    'slack-edge.com',
    'stclairsoft.com',
    'steampowered.com',
    'tableplus.com',
    'teams.cdn.office.net',
    'techsmith.com',
    'ubuntu.com',
    'umd.edu',
    'vc.logitech.com',
    'virtualbox.org',
    'warp.dev',
    'webex.com',
    'whatsapp.com',
    'xtom.com',
    'zoomgov.com',
    'zoom.us',
    'zsa.io'
  )
  AND host NOT IN (
    'balsamiq.com',
    'brave.com',
    'discord.com',
    'dl.discordapp.net',
    'dl.google.com',
    'duckduckgo.com',
    'dygma.com',
    'emacsformacosx.com',
    'getkap.co',
    'github.com',
    'krisp.ai',
    'mail.google.com',
    'manual.canon',
    'obdev.at',
    'obsidian.md',
    'obsproject.com',
    'posit.co',
    'rectangleapp.com',
    'stclairsoft.s3.amazonaws.com',
    'store.steampowered.com',
    'tableplus.com',
    'textexpander.com',
    'ubuntu.com',
    'warp-releases.storage.googleapis.com',
    'wavebox.io',
    'www.google.com',
    'www.messenger.com',
    'zoom.us'
  )
  -- Yes, these are meant to be fairly broad.
  AND host NOT LIKE 'download%'
  AND host NOT LIKE 'cdn%'
  AND host NOT LIKE '%.edu'
  AND host NOT LIKE 'github-production-release-asset-%.s3.amazonaws.com'
  AND host NOT LIKE '%.org'
  AND host NOT LIKE 'dl.%'
  AND host NOT LIKE 'dl-%'
  AND host NOT LIKE 'mirror%'
  AND host NOT LIKE 'driver.%'
  AND host NOT LIKE 'support%'
  AND host NOT LIKE 'software%'
  AND host NOT LIKE 'www.google.%'
  AND host NOT LIKE '%release%.storage.googleapis.com'
  AND NOT (
    host LIKE '%.fbcdn.net'
    AND (
      file.filename LIKE 'Messenger.%.dmg'
      OR file.filename LIKE '%WhatsApp.dmg'
    )
  )
GROUP BY
  ea.value
