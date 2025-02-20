-- Pick out exotic processes based on their command-line (events-based)
--
-- references:
--   * https://themittenmac.com/what-does-apt-activity-look-like-on-macos/
--
-- false positives:
--   * possible, but none known
--
-- tags: transient process events
-- platform: linux
-- interval: 300
SELECT
  -- Child
  pe.path AS p0_path,
  REGEX_MATCH (pe.path, '.*/(.*)', 1) AS p0_name,
  TRIM(pe.cmdline) AS p0_cmd,
  pe.cwd AS p0_cwd,
  pe.pid AS p0_pid,
  p.cgroup_path AS p0_cgroup,
  -- Parent
  pe.parent AS p1_pid,
  p1.cgroup_path AS p1_cgroup,
  TRIM(COALESCE(p1.cmdline, pe1.cmdline)) AS p1_cmd,
  COALESCE(p1.path, pe1.path) AS p1_path,
  COALESCE(p_hash1.sha256, pe_hash1.sha256) AS p1_hash,
  REGEX_MATCH (COALESCE(p1.path, pe1.path), '.*/(.*)', 1) AS p1_name,
  -- Grandparent
  COALESCE(p1.parent, pe1.parent) AS p2_pid,
  COALESCE(p1_p2.cgroup_path, pe1_p2.cgroup_path) AS p2_cgroup,
  TRIM(
    COALESCE(p1_p2.cmdline, pe1_p2.cmdline, pe1_pe2.cmdline)
  ) AS p2_cmd,
  COALESCE(p1_p2.path, pe1_p2.path, pe1_pe2.path) AS p2_path,
  COALESCE(
    p1_p2_hash.path,
    pe1_p2_hash.path,
    pe1_pe2_hash.path
  ) AS p2_hash,
  REGEX_MATCH (
    COALESCE(p1_p2.path, pe1_p2.path, pe1_pe2.path),
    '.*/(.*)',
    1
  ) AS p2_name,
  -- Exception key
  REGEX_MATCH (pe.path, '.*/(.*)', 1) || ',' || MIN(pe.euid, 500) || ',' || REGEX_MATCH (COALESCE(p1.path, pe1.path), '.*/(.*)', 1) || ',' || REGEX_MATCH (
    COALESCE(p1_p2.path, pe1_p2.path, pe1_pe2.path),
    '.*/(.*)',
    1
  ) AS exception_key
FROM
  process_events pe,
  uptime
  LEFT JOIN processes p ON pe.pid = p.pid
  -- Parents (via two paths)
  LEFT JOIN processes p1 ON pe.parent = p1.pid
  LEFT JOIN hash p_hash1 ON p1.path = p_hash1.path
  LEFT JOIN process_events pe1 ON pe.parent = pe1.pid
  AND pe1.cmdline != ''
  LEFT JOIN hash pe_hash1 ON pe1.path = pe_hash1.path
  -- Grandparents (via 3 paths)
  LEFT JOIN processes p1_p2 ON p1.parent = p1_p2.pid -- Current grandparent via parent processes
  LEFT JOIN processes pe1_p2 ON pe1.parent = pe1_p2.pid -- Current grandparent via parent events
  LEFT JOIN process_events pe1_pe2 ON pe1.parent = pe1_p2.pid
  AND pe1_pe2.cmdline != '' -- Past grandparent via parent events
  LEFT JOIN hash p1_p2_hash ON p1_p2.path = p1_p2_hash.path
  LEFT JOIN hash pe1_p2_hash ON pe1_p2.path = pe1_p2_hash.path
  LEFT JOIN hash pe1_pe2_hash ON pe1_pe2.path = pe1_pe2_hash.path
WHERE
  pe.time > (strftime('%s', 'now') -300)
  AND pe.cmdline != ''
  AND (
    p0_name IN (
      'bitspin',
      'bpftool',
      'heyoka',
      'nstx',
      'dnscat2',
      'tuns',
      'iodine',
      'esxcli',
      'vim-cmd',
      'minerd',
      'cpuminer-multi',
      'cpuminer',
      'httpdns',
      'rshell',
      'rsh',
      'xmrig',
      'incbit',
      'insmod',
      'kmod',
      'lushput',
      'mkfifo',
      'msfvenom',
      'nc',
      'socat'
    )
    -- Chrome Stealer
    OR p0_cmd LIKE '%chrome%-load-extension%'
    -- Known attack scripts
    OR p0_name LIKE '%pwn%'
    OR p0_name LIKE '%attack%'
    -- Unusual behaviors
    OR p0_cmd LIKE '%ufw disable%'
    OR p0_cmd LIKE '%iptables -P % ACCEPT%'
    OR p0_cmd LIKE '%iptables -F%'
    OR p0_cmd LIKE '%chattr -ia%'
    OR p0_cmd LIKE '%chmod %777 %'
    OR (
      INSTR(p0_cmd, 'history') > 0
      AND p0_cmd LIKE '%history'
      AND p0_cmd NOT LIKE 'man %'
    )
    OR p0_cmd LIKE '%touch%acmr%'
    OR p0_cmd LIKE '%touch -r%'
    OR p0_cmd LIKE '%ld.so.preload%'
    OR p0_cmd LIKE '%urllib.urlopen%'
    OR p0_cmd LIKE '%nohup%tmp%'
    OR p0_cmd LIKE '%iptables stop'
    OR p0_cmd LIKE '%systemctl stop firewalld%'
    OR p0_cmd LIKE '%systemctl disable firewalld%'
    OR p0_cmd LIKE '%pkill -f%'
    OR (
      p0_cmd LIKE '%xargs kill -9%'
      AND pe.euid = 0
    )
    OR p0_cmd LIKE '%rm -rf /boot%'
    OR p0_cmd LIKE '%nohup /bin/bash%'
    OR p0_cmd LIKE '%echo%|%base64 --decode %|%'
    OR p0_cmd LIKE '%UserKnownHostsFile=/dev/null%'
    -- Crypto miners
    OR p0_cmd LIKE '%monero%'
    OR p0_cmd LIKE '%nanopool%'
    OR p0_cmd LIKE '%nicehash%'
    OR p0_cmd LIKE '%stratum%'
    -- Random keywords
    OR p0_cmd LIKE '%ransom%'
    -- Reverse shells
    OR p0_cmd LIKE '%/dev/tcp/%'
    OR p0_cmd LIKE '%/dev/udp/%'
    OR p0_cmd LIKE '%fsockopen%'
    OR p0_cmd LIKE '%openssl%quiet%'
    OR p0_cmd LIKE '%pty.spawn%'
    OR (
      p0_cmd LIKE '%sh -i'
      AND NOT p1_name IN ('sh', 'java')
    )
    OR p0_cmd LIKE '%socat%'
    OR p0_cmd LIKE '%SOCK_STREAM%'
    OR INSTR(p0_cmd, 'Socket.') > 0
    OR (
      p0_cmd LIKE '%tail -f /dev/null%'
      AND p.cgroup_path NOT LIKE '/system.slice/docker-%'
    )
  ) -- Things that could reasonably happen at boot.
  AND NOT (
    pe.path IN ('/usr/bin/kmod', '/bin/kmod')
    AND p1_path = '/usr/lib/systemd/systemd'
    AND p1_cmd = '/sbin/init'
  )
  AND NOT (
    pe.path IN ('/usr/bin/kmod', '/bin/kmod')
    AND p1_name IN (
      'firewalld',
      'mkinitramfs',
      'systemd',
      'dockerd',
      'kube-proxy'
    )
  )
  AND NOT (
    p0_cmd LIKE '/usr/bin/modprobe %'
    AND p1_cgroup = '/system.slice/firewalld.service'
  )
  AND NOT (
    pe.path IN ('/usr/bin/kmod', '/bin/kmod')
    AND uptime.total_seconds < 15
  )
  AND NOT (
    pe.path = '/usr/bin/mkfifo'
    AND (
      p0_cmd LIKE '%/org.gpgtools.log.%/fifo'
      OR p0_cmd LIKE 'mkfifo -- /private/var/folders/%/T/gitstatus.POWERLEVEL9K.501.%.fifo'
      OR p0_cmd LIKE 'mkfifo -- /var/folders/%/T//p10k.worker.501.%.fifo'
    )
  )
  AND NOT p0_cmd IN ('lsmod')
  AND NOT p0_cmd LIKE 'dirname %history'
  AND NOT p0_cmd LIKE 'find . -executable -type f -name %grep -l GNU Libtool%touch -r%'
  AND NOT p0_cmd LIKE 'modinfo -k%'
  AND NOT p0_cmd LIKE 'modprobe -ab%'
  AND NOT p0_cmd LIKE 'modprobe --all%'
  AND NOT p0_cmd LIKE '%modprobe aufs'
  AND NOT p0_cmd LIKE '%modprobe overlay'
  AND NOT p0_cmd LIKE '%modprobe nf_nat_netbios_ns'
  AND NOT p0_cmd LIKE '%modprobe -va%'
  AND NOT p0_cmd LIKE 'pkill -f cut -c3%'
  AND NOT p0_cmd LIKE 'tail /%history'
  AND NOT p0_cmd LIKE '%/usr/bin/cmake%Socket.cpp'
  AND NOT p0_cmd LIKE '%/usr/bin/cmake%Socket.h'
  AND NOT p0_name IN ('cc1', 'compile', 'cmake', 'cc1plus')
