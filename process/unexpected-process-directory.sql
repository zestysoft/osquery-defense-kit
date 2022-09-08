SELECT p.pid,
    p.name,
    p.path,
    f.directory,
    p.cmdline
FROM processes p
    JOIN file f ON p.path = f.path
WHERE directory NOT LIKE '/Applications/%.app/%'
    AND directory NOT LIKE '/home/%'
    AND directory NOT LIKE '/Library/Apple/System/Library%'
    AND directory NOT LIKE '/Library/Application Support/%/Contents/MacOS'
    AND directory NOT LIKE '/Library/Audio/Plug-Ins/%/Contents/MacOS'
    AND directory NOT LIKE '/Library/CoreMediaIO/Plug-Ins/%'
    AND directory NOT LIKE '/Library/Internet Plug-Ins/%/Contents/MacOS'
    AND directory NOT LIKE '/Library/SystemExtensions/%/at.obdev.littlesnitch.networkextension.systemextension/Contents/MacOS'
    AND directory NOT LIKE '/Library/SystemExtensions/%/com.objective-see.lulu.extension.systemextension/Contents/MacOS'
    AND directory NOT LIKE '/Library/SystemExtensions/%/com.objective-see.lulu.extension.systemextension/Contents/MacOS'
    AND directory NOT LIKE '/Library/SystemExtensions/%/com.opalcamera.OpalCamera.opalCameraExtension.systemextension/Contents/MacOS'
    AND directory NOT LIKE '/nix/store/%/bin'
    AND directory NOT LIKE '/nix/store/%/lib/%'
    AND directory NOT LIKE '/nix/store/%/libexec'
    AND directory NOT LIKE '/nix/store/%/libexec/%'
    AND directory NOT LIKE '/opt/%'
    AND directory NOT LIKE '/opt/homebrew/%'
    AND directory NOT LIKE '/private/var/db/com.apple.xpc.roleaccountd.staging/%.xpc/Contents/MacOS'
    AND directory NOT LIKE '/private/var/folders/%/Contents/Frameworks/%'
    AND directory NOT LIKE '/private/var/folders/%/Contents/MacOS'
    AND directory NOT LIKE '/private/var/folders/%/Contents/MacOS'
    AND directory NOT LIKE '/private/var/folders/%/go-build%'
    AND directory NOT LIKE '/tmp/go-build%'
    AND directory NOT LIKE '/snap/%'
    AND directory NOT LIKE '/System/%'
    AND directory NOT LIKE '/Users/%'
    AND directory NOT LIKE '/Users/%/Library/Application Support/%'
    AND directory NOT LIKE '/usr/libexec/%'
    AND directory NOT LIKE '/usr/local/%/bin/%'
    AND directory NOT LIKE '/usr/local/%bin'
    AND directory NOT LIKE '/usr/local/%libexec'
    AND directory NOT LIKE '/usr/lib/electron%'
    AND directory NOT IN (
        '/bin',
        '/Library/DropboxHelperTools/Dropbox_u501',
        '/sbin',
        '/usr/bin',
        '/usr/lib',
        '/usr/lib/bluetooth',
        '/usr/lib/cups/notifier',
        '/usr/lib/evolution-data-server',
        '/usr/lib/fwupd',
        '/usr/lib/ibus',
        '/usr/lib/libreoffice/program',
        '/usr/lib/polkit-1',
        '/usr/lib/slack',
        '/usr/lib/snapd',
        '/usr/lib/systemd',
        '/usr/lib/telepathy',
        '/usr/lib/udisks2',
        '/usr/lib/xorg',
        '/usr/lib64/firefox',
        '/usr/libexec',
        '/usr/libexec/ApplicationFirewall',
        '/usr/libexec/rosetta',
        '/usr/sbin',
        '/usr/share/code'
    )
    AND f.path NOT IN (
        '/usr/libexec/AssetCache/AssetCache',
        '/Library/PrivilegedHelperTools/com.adobe.acc.installer.v2',
        '/Library/PrivilegedHelperTools/com.docker.vmnetd',
        '/Library/PrivilegedHelperTools/com.macpaw.CleanMyMac4.Agent',
        '/Library/PrivilegedHelperTools/keybase.Helper'
    )
    AND directory NOT LIKE '/Library/Application Support/Adobe/%';