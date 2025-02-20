-- Programs which are writing an unusually large amount of data
--
-- Can be used to detect ransomware
--
-- false positives:
--   * Package managers
--   * Backup software
--
-- references:
--   * https://attack.mitre.org/tactics/TA0009/ (Collection)
--
-- tags: transient process
SELECT
  p.name,
  p.cgroup_path,
  p.path,
  p.pid,
  p.cmdline,
  p.on_disk,
  p.parent,
  p.start_time,
  hash.sha256,
  p.disk_bytes_written,
  p.cwd,
  (strftime('%s', 'now') - start_time) AS age,
  disk_bytes_written / (strftime('%s', 'now') - start_time) AS bytes_per_second
FROM
  processes p
  LEFT JOIN hash ON p.path = hash.path
WHERE
  bytes_per_second > 7500000
  AND age > 30
  AND pid > 2
  AND p.path NOT IN (
    '/bin/bash',
    '/bin-busybox',
    '/opt/homebrew/bin/qemu-system-aarch64',
    '/usr/bin/apt',
    '/usr/bin/aptd',
    '/usr/bin/pacman',
    '/usr/bin/git',
    '/usr/bin/bash',
    '/usr/lib/baloo_file_extractor',
    '/usr/bin/bwrap',
    '/usr/bin/curl',
    '/usr/bin/darktable',
    '/usr/bin/dockerd',
    '/usr/bin/fish',
    '/usr/bin/gnome-shell',
    '/usr/bin/gnome-software',
    '/usr/bin/make',
    '/usr/bin/melange',
    '/usr/bin/qemu-system-x86_64',
    '/usr/bin/yay',
    '/usr/bin/zsh',
    '/usr/lib64/thunderbird/thunderbird',
    '/usr/libexec/coreduetd',
    '/usr/share/spotify-client/spotify',
    '/Library/Application Support/Adobe/Adobe Desktop Common/HDBox/Setup',
    '/usr/libexec/flatpak-system-helper',
    '/usr/libexec/logd_helper',
    '/usr/libexec/packagekitd',
    '/usr/libexec/rosetta/oahd',
    '/usr/libexec/secd',
    '/usr/libexec/sharingd',
    '/usr/lib/flatpak-system-helper',
    '/usr/lib/systemd/systemd',
    '/usr/lib/systemd/systemd-journald',
    '/usr/sbin/screencapture'
  )
  AND NOT (
    name LIKE 'jbd%/dm-%'
    AND on_disk = -1
  )
  AND NOT (
    name = 'bindfs'
    AND cmdline LIKE 'bindfs -f -o fsname=%'
  )
  AND NOT (
    name = 'btrfs-transaction'
    AND on_disk = -1
  )
  AND NOT (
    name = 'kernel_task'
    AND p.path = ''
    AND parent IN (0, 1)
    AND on_disk = -1
  )
  AND NOT (
    name = 'launchd'
    AND p.path = '/sbin/launchd'
    AND parent = 0
  )
  AND NOT (
    name = 'logd'
    AND cmdline = '/usr/libexec/logd'
    AND parent = 1
  )
  AND NOT (
    name = 'aptd'
    AND cmdline = '/usr/bin/python3 /usr/sbin/aptd'
  )
  AND NOT name IN (
    'baloo_file_extr',
    'bwrap',
    'cargo',
    'chrome',
    'Cisco WebEx Start',
    'com.apple.MobileSoftwareUpdate.UpdateBrainService',
    'com.apple.NRD.UpdateBrainService',
    'containerd',
    'containerd-',
    'containerd-shim',
    'darkfiles',
    'dlv',
    'dnf',
    'dnf-automatic',
    'docker-index',
    'esbuild',
    'firefox',
    'fsdaemon',
    'go',
    'goland',
    'golangci-lint-v',
    'gopls',
    'grype',
    'idea',
    'Install',
    'java',
    'jetbrains-toolb',
    'launcher',
    'limactl',
    'nessusd',
    'ninja',
    'node',
    'photorec',
    'qemu-system-aarch64',
    'qemu-system-x86_64',
    'rsync',
    'rust-analyzer',
    'rustup',
    'slack',
    'snyk',
    'spotify',
    'staticcheck',
    'steam',
    'syft',
    'tracker-miner-f',
    'trivy',
    'trivy-db',
    'wineserver',
    'yum'
  )
  AND p.path NOT LIKE '/Applications/%.app/Contents/%'
  AND p.path NOT LIKE '/home/%/.local/share/Steam'
  AND p.path NOT LIKE '/nix/store/%/bin/%sh'
  AND p.path NOT LIKE '/nix/store/%/bin/nix'
  AND p.path NOT LIKE '/System/Applications/%'
  AND p.path NOT LIKE '/System/Library/%'
  AND p.path NOT LIKE '/usr/local/kolide-k2/bin/osqueryd-updates/%/osqueryd'
  AND p.path NOT LIKE '/nix/store/%kolide-launcher-%/bin/launcher'
  AND NOT cmdline LIKE '%/lib/gcloud.py components update'
  AND NOT cgroup_path LIKE '/system.slice/docker-%'
  AND NOT p.path = '/opt/osquery/lib/osquery.app/Contents/MacOS/osqueryd'
