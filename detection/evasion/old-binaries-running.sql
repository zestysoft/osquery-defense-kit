-- Alert on programs running that are unusually old
--
-- false positive:
--   * legimitely ancient programs. For instance, printer drivers.
--
-- references:
--   * https://attack.mitre.org/techniques/T1070/006/ (Indicator Removal on Host: Timestomp)
--
-- tags: transient process state
SELECT
  p.path,
  p.cmdline,
  p.cwd,
  p.pid,
  p.name,
  f.mtime,
  f.ctime,
  p.cgroup_path,
  ((strftime('%s', 'now') - f.ctime) / 86400) AS ctime_age_days,
  ((strftime('%s', 'now') - f.mtime) / 86400) AS mtime_age_days,
  ((strftime('%s', 'now') - f.btime) / 86400) AS btime_age_days,
  h.sha256,
  f.uid,
  m.data,
  f.gid
FROM
  processes p
  LEFT JOIN file f ON p.path = f.path
  LEFT JOIN hash h ON p.path = h.path
  LEFT JOIN magic m ON p.path = m.path
WHERE
  (
    ctime_age_days > 1050
    OR mtime_age_days > 1050
  )
  -- Jan 1st, 1980 (the source of many false positives)
  AND f.mtime > 315561600
  AND f.path NOT LIKE '/home/%/idea-IU-223.8214.52/%'
  AND f.path NOT IN (
    '/Applications/Divvy.app/Contents/MacOS/Divvy',
    '/Applications/Emacs.app/Contents/MacOS/Emacs-x86_64-10_14',
    '/Applications/Gitter.app/Contents/Library/LoginItems/GitterHelperApp.app/Contents/MacOS/GitterHelperApp',
    '/Applications/Pandora.app/Contents/Frameworks/Electron Framework.framework/Versions/A/Resources/crashpad_handler',
    '/Applications/Skitch.app/Contents/Library/LoginItems/J8RPQ294UB.com.skitch.SkitchHelper.app/Contents/MacOS/J8RPQ294UB.com.skitch.SkitchHelper',
    '/Library/Application Support/Logitech/com.logitech.vc.LogiVCCoreService/LogiVCCoreService.app/Contents/MacOS/LogiVCCoreService',
    '/Library/Printers/Brother/Utilities/Server/LOGINserver.app/Contents/MacOS/LOGINserver',
    '/Library/Printers/Brother/Utilities/Server/NETserver.app/Contents/MacOS/NETserver',
    '/Library/Printers/Brother/Utilities/Server/USBAppControl.app/Contents/MacOS/USBAppControl',
    '/Library/Printers/Brother/Utilities/Server/USBserver.app/Contents/MacOS/USBserver',
    '/Library/Printers/Brother/Utilities/Server/WorkflowAppControl.app/Contents/MacOS/WorkflowAppControl',
    '/opt/homebrew/Cellar/bash/5.1.16/bin/bash',
    '/opt/homebrew/Cellar/kail/0.15.0/bin/kail',
    '/opt/homebrew/Cellar/watch/3.3.16/bin/watch',
    '/snap/brackets/138/opt/brackets/Brackets',
    '/snap/brackets/138/opt/brackets/Brackets-node',
    '/usr/bin/i3blocks',
    '/usr/bin/sshfs',
    '/usr/bin/xss-lock'
  )
  AND p.name NOT IN (
    'buildkitd',
    'kail',
    'kail',
    'BluejeansHelper',
    'J8RPQ294UB.com.skitch.SkitchHelper',
    'Pandora',
    'Pandora Helper',
    'dlv'
  )
GROUP BY
  p.pid,
  p.path
