# DNS Switcher v3.1
# Windows PowerShell 5.1+ | Administrator required for DNS changes
# DNS backups preserve whether each address family used static DNS or automatic DNS.
#
# v3.1 changes
#   - FIXED: "Restore backup" to automatic DNS always failed (bad netsh adapter name).
#   - FIXED: providers without IPv6 left the previous IPv6 resolver active.
#   - FIXED: unhandled errors closed the elevated window instantly.
#   - FIXED: single-adapter systems could break adapter selection.
#   - NEW:   ASCII-art "DNS SWITCHER" banner in the header.
#   - NEW:   real ICMP ping + UDP DNS benchmark, all providers in parallel, ~45 seconds.

$ErrorActionPreference = "Stop"
$script:Version = "3.1"
$script:BackupDir = Join-Path $PSScriptRoot "DNS-Backups"
$script:SelectedAdapter = $null
$script:BenchmarkSeconds = 45   # total benchmark time (finishes within ~1-2 s of this)

try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch { }   # lets the banner blocks render

$script:Providers = [ordered]@{
    "1" = @{
        Name = "Cloudflare"
        IPv4 = @("1.1.1.1", "1.0.0.1")
        IPv6 = @("2606:4700:4700::1111", "2606:4700:4700::1001")
        Note = "Fast public resolver"
    }
    "2" = @{
        Name = "Google Public DNS"
        IPv4 = @("8.8.8.8", "8.8.4.4")
        IPv6 = @("2001:4860:4860::8888", "2001:4860:4860::8844")
        Note = "General-purpose public resolver"
    }
    "3" = @{
        Name = "AdGuard DNS"
        IPv4 = @("94.140.14.14", "94.140.15.15")
        IPv6 = @("2a10:50c0::ad1:ff", "2a10:50c0::ad2:ff")
        Note = "Blocks many ads and trackers"
    }
    "4" = @{
        Name = "Quad9"
        IPv4 = @("9.9.9.9", "149.112.112.112")
        IPv6 = @("2620:fe::fe", "2620:fe::9")
        Note = "Security-focused resolver"
    }
    "5" = @{
        Name = "OpenDNS"
        IPv4 = @("208.67.222.222", "208.67.220.220")
        IPv6 = @("2620:119:35::35", "2620:119:53::53")
        Note = "Cisco public resolver"
    }
    "6" = @{
        Name = "Cloudflare Family"
        IPv4 = @("1.1.1.3", "1.0.0.3")
        IPv6 = @("2606:4700:4700::1113", "2606:4700:4700::1003")
        Note = "Blocks malware and adult content"
    }
}

$script:Banner = @(
    '░█▀▀▄ ░█▄─░█ ░█▀▀▀█    ░█▀▀▀█ ░█──░█ ▀█▀ ▀▀█▀▀ ░█▀▀█ ░█─░█ ░█▀▀▀ ░█▀▀█',
    '░█─░█ ░█░█░█ ─▀▀▀▄▄    ─▀▀▀▄▄ ░█░█░█ ░█─ ─░█── ░█─── ░█▀▀█ ░█▀▀▀ ░█▄▄▀',
    '░█▄▄▀ ░█──▀█ ░█▄▄▄█    ░█▄▄▄█ ░█▄▀▄█ ▄█▄ ─░█── ░█▄▄█ ░█─░█ ░█▄▄▄ ░█─░█'
)

function Write-Header {
    Clear-Host
    $bar = "=" * $script:Banner[0].Length
    Write-Host $bar -ForegroundColor DarkCyan
    foreach ($row in $script:Banner) { Write-Host $row -ForegroundColor Cyan }
    Write-Host ("  PowerShell DNS Management Tool  |  v{0}" -f $script:Version) -ForegroundColor Gray
    Write-Host $bar -ForegroundColor DarkCyan
    if ($script:SelectedAdapter) {
        Write-Host (" Adapter: {0}  |  Interface index: {1}" -f $script:SelectedAdapter.Name, $script:SelectedAdapter.ifIndex) -ForegroundColor Yellow
    }
    Write-Host ""
}

function Pause-Menu {
    Write-Host ""
    [void](Read-Host "Press Enter to continue")
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Administrator {
    if (Test-Administrator) { return }
    Write-Host "Administrator permission is required. Requesting elevation..." -ForegroundColor Yellow
    try {
        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
        Start-Process -FilePath "powershell.exe" -Verb RunAs -ArgumentList $arguments
    } catch {
        Write-Host "Elevation was cancelled or failed: $($_.Exception.Message)" -ForegroundColor Red
        Pause-Menu
    }
    exit
}

function Get-AvailableAdapters {
    try {
        @(Get-NetAdapter -ErrorAction Stop | Sort-Object ifIndex)
    } catch {
        Write-Host "Unable to read network adapters: $($_.Exception.Message)" -ForegroundColor Red
        @()
    }
}

function Select-Adapter {
    # FIX: wrap in @() - with exactly one adapter the function returns a bare object,
    # and indexing/Count on it is not reliable.
    $adapters = @(Get-AvailableAdapters)
    if ($adapters.Count -eq 0) {
        Write-Host "No network adapters were found." -ForegroundColor Red
        Pause-Menu
        return
    }

    while ($true) {
        Write-Header
        Write-Host "NETWORK ADAPTERS" -ForegroundColor Cyan
        for ($i = 0; $i -lt $adapters.Count; $i++) {
            $a = $adapters[$i]
            $statusColor = if ($a.Status -eq "Up") { "Green" } else { "DarkGray" }
            Write-Host (" {0}. {1}  [{2}]  ifIndex: {3}" -f ($i + 1), $a.Name, $a.Status, $a.ifIndex) -ForegroundColor $statusColor
            Write-Host ("    {0}" -f $a.InterfaceDescription) -ForegroundColor DarkGray
        }
        Write-Host ""
        $answer = Read-Host "Choose adapter number (Q to cancel)"
        if ($answer -match '^[Qq]$') { return }
        $number = 0
        if ([int]::TryParse($answer, [ref]$number) -and $number -ge 1 -and $number -le $adapters.Count) {
            $script:SelectedAdapter = $adapters[$number - 1]
            return
        }
        Write-Host "Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

function Get-RegistryNameServer {
    param(
        [Parameter(Mandatory=$true)][string]$InterfaceGuid,
        [Parameter(Mandatory=$true)][ValidateSet("IPv4","IPv6")][string]$Family
    )
    $guid = $InterfaceGuid.Trim("{}")
    if ($Family -eq "IPv4") {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{$guid}"
    } else {
        $path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\Interfaces\{$guid}"
    }

    try {
        $item = Get-ItemProperty -LiteralPath $path -Name NameServer -ErrorAction Stop
        if ($null -eq $item.NameServer) { return "" }
        return [string]$item.NameServer
    } catch {
        return ""
    }
}

function Get-CurrentDns {
    param([Parameter(Mandatory=$true)]$Adapter)
    $v4 = @()
    $v6 = @()
    try {
        $v4 = @((Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction Stop).ServerAddresses)
    } catch {}
    try {
        $v6 = @((Get-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv6 -ErrorAction Stop).ServerAddresses)
    } catch {}
    return [pscustomobject]@{ IPv4 = $v4; IPv6 = $v6 }
}

function Show-CurrentDns {
    if (-not $script:SelectedAdapter) { return }
    $dns = Get-CurrentDns -Adapter $script:SelectedAdapter
    Write-Host "CURRENT DNS CONFIGURATION" -ForegroundColor Cyan
    Write-Host " IPv4:" -ForegroundColor Gray
    if ($dns.IPv4.Count) { $dns.IPv4 | ForEach-Object { Write-Host "   $_" } } else { Write-Host "   (none reported)" -ForegroundColor DarkGray }
    Write-Host " IPv6:" -ForegroundColor Gray
    if ($dns.IPv6.Count) { $dns.IPv6 | ForEach-Object { Write-Host "   $_" } } else { Write-Host "   (none reported)" -ForegroundColor DarkGray }
}

function Clear-DnsCacheSafe {
    # FIX: with $ErrorActionPreference = "Stop" an unguarded Clear-DnsClientCache failure
    # killed the whole script.
    try {
        Clear-DnsClientCache -ErrorAction Stop
        return $true
    } catch {
        Write-Host "Could not flush DNS cache: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Save-DnsBackup {
    param([Parameter(Mandatory=$true)]$Adapter)

    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }

    $guid = [string]$Adapter.InterfaceGuid
    $current = Get-CurrentDns -Adapter $Adapter
    $backup = [pscustomobject]@{
        ToolVersion = $script:Version
        SavedAt = (Get-Date).ToString("o")
        AdapterName = [string]$Adapter.Name
        InterfaceGuid = $guid
        InterfaceIndex = [int]$Adapter.ifIndex
        IPv4NameServer = Get-RegistryNameServer -InterfaceGuid $guid -Family IPv4
        IPv6NameServer = Get-RegistryNameServer -InterfaceGuid $guid -Family IPv6
        CurrentIPv4 = @($current.IPv4)
        CurrentIPv6 = @($current.IPv6)
    }

    $stamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $safeGuid = $guid -replace '[{}]', ''
    $file = Join-Path $script:BackupDir ("DNS-{0}-{1}.json" -f $safeGuid, $stamp)
    $backup | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $file -Encoding UTF8
    Write-Host "Backup saved: $file" -ForegroundColor Green
    return $file
}

function Convert-BackupServers {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { return @() }
    return @($Value -split '[,;\s]+' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Set-DnsAddresses {
    # Applies IPv4 and IPv6 DNS to an interface. An empty list means "automatic" for
    # that family. Returns an array of problem strings (empty array = everything worked).
    #
    # FIX: the old code used netsh with name="$script:SelectedAdapter.Name", which expands
    # to the adapter OBJECT's type text plus ".Name", so restoring automatic DNS always
    # failed. Set-DnsClientServerAddress -ResetServerAddresses resets BOTH families, so
    # it is used as the clean slate and the family that must stay static is set afterwards.
    param(
        [Parameter(Mandatory=$true)][int]$InterfaceIndex,
        [string[]]$IPv4,
        [string[]]$IPv6
    )
    $problems = @()
    $v4 = @($IPv4 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    $v6 = @($IPv6 | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

    if ($v4.Count -eq 0 -or $v6.Count -eq 0) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ResetServerAddresses -ErrorAction Stop | Out-Null
        } catch {
            $problems += "Reset to automatic: $($_.Exception.Message)"
            return $problems
        }
    }
    if ($v4.Count -gt 0) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $v4 -ErrorAction Stop | Out-Null
        } catch {
            $problems += "IPv4: $($_.Exception.Message)"
        }
    }
    if ($v6.Count -gt 0) {
        try {
            Set-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -ServerAddresses $v6 -ErrorAction Stop | Out-Null
        } catch {
            $problems += "IPv6: $($_.Exception.Message) (IPv6 may be disabled on this adapter)"
        }
    }
    return $problems
}

function Restore-DnsBackup {
    if (-not $script:SelectedAdapter) { return }
    if (-not (Test-Path $script:BackupDir)) {
        Write-Host "No backup folder exists yet." -ForegroundColor Yellow
        return
    }

    $guid = ([string]$script:SelectedAdapter.InterfaceGuid).Trim("{}")
    $files = @(Get-ChildItem -LiteralPath $script:BackupDir -Filter "DNS-$guid-*.json" -File | Sort-Object LastWriteTime -Descending)
    if ($files.Count -eq 0) {
        Write-Host "No backup found for this adapter." -ForegroundColor Yellow
        return
    }

    Write-Host "Available backups for $($script:SelectedAdapter.Name):" -ForegroundColor Cyan
    for ($i = 0; $i -lt $files.Count; $i++) {
        Write-Host (" {0}. {1}" -f ($i + 1), $files[$i].Name)
    }
    $choice = Read-Host "Select backup number (Enter = latest, Q = cancel)"
    if ($choice -match '^[Qq]$') { return }
    $selected = $files[0]
    if (-not [string]::IsNullOrWhiteSpace($choice)) {
        $n = 0
        if (-not [int]::TryParse($choice, [ref]$n) -or $n -lt 1 -or $n -gt $files.Count) {
            Write-Host "Invalid backup selection." -ForegroundColor Red
            return
        }
        $selected = $files[$n - 1]
    }

    $confirm = Read-Host "Restore DNS from $($selected.Name)? (Y/N)"
    if ($confirm -notmatch '^[Yy]$') { return }

    try {
        $data = Get-Content -LiteralPath $selected.FullName -Raw | ConvertFrom-Json
        if (([string]$data.InterfaceGuid).Trim("{}") -ne $guid) {
            throw "Backup belongs to a different network adapter."
        }
        $props = @($data.PSObject.Properties.Name)
        if (($props -notcontains "IPv4NameServer") -or ($props -notcontains "IPv6NameServer")) {
            throw "Backup file is incomplete or damaged (DNS fields missing)."
        }

        $v4 = @(Convert-BackupServers -Value ([string]$data.IPv4NameServer))
        $v6 = @(Convert-BackupServers -Value ([string]$data.IPv6NameServer))
        $problems = @(Set-DnsAddresses -InterfaceIndex $script:SelectedAdapter.ifIndex -IPv4 $v4 -IPv6 $v6)
        [void](Clear-DnsCacheSafe)

        if ($problems.Count -eq 0) {
            if ($v4.Count -gt 0) { Write-Host " IPv4 restored to saved static DNS: $($v4 -join ', ')" -ForegroundColor Green }
            else { Write-Host " IPv4 restored to automatic DNS (DHCP/default)." -ForegroundColor Green }
            if ($v6.Count -gt 0) { Write-Host " IPv6 restored to saved static DNS: $($v6 -join ', ')" -ForegroundColor Green }
            else { Write-Host " IPv6 restored to automatic DNS (DHCP/default)." -ForegroundColor Green }
            Write-Host "Restore finished. DNS cache flushed." -ForegroundColor Green
        } else {
            Write-Host "Restore was only partially applied:" -ForegroundColor Yellow
            $problems | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
        }
    } catch {
        Write-Host "Restore failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Set-DnsProvider {
    param([string]$ProviderKey)
    if (-not $script:SelectedAdapter) { return }
    $provider = $script:Providers[$ProviderKey]
    if (-not $provider) { return }

    Write-Host ""
    Write-Host "Before changing DNS, saving the current configuration..." -ForegroundColor Yellow
    try {
        Save-DnsBackup -Adapter $script:SelectedAdapter | Out-Null
    } catch {
        Write-Host "Backup failed. DNS was NOT changed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    # FIX: a provider without IPv6 addresses used to leave the previous IPv6 resolver in
    # place, so Windows could keep using the OLD provider over IPv6. Empty IPv6 list now
    # resets IPv6 to automatic instead.
    $problems = @(Set-DnsAddresses -InterfaceIndex $script:SelectedAdapter.ifIndex -IPv4 $provider.IPv4 -IPv6 $provider.IPv6)
    [void](Clear-DnsCacheSafe)

    if ($problems.Count -eq 0) {
        Write-Host "$($provider.Name) DNS configuration applied." -ForegroundColor Green
        if ($provider.IPv6.Count -eq 0) {
            Write-Host "Note: this provider has no IPv6 resolvers, so IPv6 DNS was reset to automatic (your router/ISP may supply it)." -ForegroundColor Yellow
        }
    } else {
        Write-Host "DNS was only partially applied:" -ForegroundColor Yellow
        $problems | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
        Write-Host "Use Restore DNS Backup if you want to return to the saved configuration." -ForegroundColor Yellow
    }
    Show-CurrentDns
}

# ----------------------------------------------------------------------------------------
# Benchmark: real ICMP ping + UDP DNS query timing, one worker thread per target.
# Every target is probed once per second for the whole test window, so all providers are
# measured at the same moments under the same network conditions.
# ----------------------------------------------------------------------------------------
$script:BenchmarkWorker = {
    param($Server, $DurationSec, $TimeoutMs, $Domains)

    $ping = New-Object System.Net.NetworkInformation.Ping
    $pingMs = New-Object 'System.Collections.Generic.List[double]'
    $dnsMs = New-Object 'System.Collections.Generic.List[double]'
    $pingSent = 0
    $dnsSent = 0
    $round = 0
    $clock = [System.Diagnostics.Stopwatch]::StartNew()

    while ($clock.Elapsed.TotalSeconds -lt $DurationSec) {
        $roundStart = $clock.ElapsedMilliseconds

        # ICMP echo (this is what "ping" measures)
        $pingSent++
        try {
            $reply = $ping.Send($Server, $TimeoutMs)
            if ($reply.Status -eq [System.Net.NetworkInformation.IPStatus]::Success) {
                $pingMs.Add([double]$reply.RoundtripTime)
            }
        } catch { }

        # Raw DNS query over UDP/53: no PowerShell cmdlet overhead, no Windows cache
        $dnsSent++
        $udp = $null
        try {
            $domain = [string]$Domains[$round % $Domains.Count]
            $id = Get-Random -Minimum 1 -Maximum 65535
            $packet = New-Object 'System.Collections.Generic.List[byte]'
            $packet.Add([byte]($id -shr 8))
            $packet.Add([byte]($id -band 0xFF))
            # flags: recursion desired | QDCOUNT=1 | AN/NS/AR = 0
            $packet.AddRange([byte[]]@(0x01, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00))
            foreach ($label in $domain.Split('.')) {
                $labelBytes = [System.Text.Encoding]::ASCII.GetBytes($label)
                $packet.Add([byte]$labelBytes.Length)
                $packet.AddRange($labelBytes)
            }
            $packet.Add([byte]0)
            $packet.AddRange([byte[]]@(0x00, 0x01, 0x00, 0x01))   # QTYPE=A, QCLASS=IN
            $bytes = $packet.ToArray()

            $udp = New-Object System.Net.Sockets.UdpClient
            $udp.Client.ReceiveTimeout = $TimeoutMs
            $udp.Connect($Server, 53)
            $watch = [System.Diagnostics.Stopwatch]::StartNew()
            [void]$udp.Send($bytes, $bytes.Length)
            $remote = [System.Net.IPEndPoint]::new([System.Net.IPAddress]::Any, 0)
            $response = $udp.Receive([ref]$remote)
            $watch.Stop()

            # valid answer = same ID, QR bit set, RCODE 0 (NOERROR)
            if ($response.Length -ge 12 -and
                $response[0] -eq $bytes[0] -and $response[1] -eq $bytes[1] -and
                (($response[2] -band 0x80) -ne 0) -and
                (($response[3] -band 0x0F) -eq 0)) {
                $dnsMs.Add([double]$watch.Elapsed.TotalMilliseconds)
            }
        } catch {
        } finally {
            if ($null -ne $udp) { try { $udp.Close() } catch { } }
        }

        $round++
        $spent = $clock.ElapsedMilliseconds - $roundStart
        if ($spent -lt 1000) { Start-Sleep -Milliseconds (1000 - [int]$spent) }
    }

    [pscustomobject]@{
        Server   = $Server
        PingSent = $pingSent
        Ping     = $pingMs.ToArray()
        DnsSent  = $dnsSent
        Dns      = $dnsMs.ToArray()
    }
}

function Get-LatencyStats {
    param([double[]]$Values)
    $v = @($Values)
    if ($v.Count -eq 0) { return $null }
    $sorted = @($v | Sort-Object)
    $avg = ($v | Measure-Object -Average).Average
    $mid = [int][math]::Floor($sorted.Count / 2)
    if ($sorted.Count % 2 -eq 1) {
        $median = $sorted[$mid]
    } else {
        $median = ($sorted[$mid - 1] + $sorted[$mid]) / 2
    }
    $jitter = 0.0
    if ($v.Count -gt 1) {
        $sum = 0.0
        for ($i = 1; $i -lt $v.Count; $i++) { $sum += [math]::Abs($v[$i] - $v[$i - 1]) }
        $jitter = $sum / ($v.Count - 1)
    }
    return [pscustomobject]@{
        Avg = [double]$avg; Min = [double]$sorted[0]; Max = [double]$sorted[$sorted.Count - 1]
        Median = [double]$median; Jitter = [double]$jitter; Count = $v.Count
    }
}

function ConvertTo-MsText {
    param($Value)
    if ($null -eq $Value) { return "-" }
    return ("{0:N1}" -f [double]$Value)
}

function Run-DnsBenchmark {
    $duration = [int]$script:BenchmarkSeconds
    $timeoutMs = 900
    $domains = @("example.com", "microsoft.com", "cloudflare.com", "wikipedia.org", "google.com")

    # Targets: primary IPv4 of every provider, plus the adapter's current DNS if it is not
    # one of the known providers (e.g. ISP or router DNS) so you can compare against it.
    $targets = @()
    foreach ($key in $script:Providers.Keys) {
        $p = $script:Providers[$key]
        $targets += [pscustomobject]@{ Name = [string]$p.Name; Server = [string]$p.IPv4[0] }
    }
    if ($script:SelectedAdapter) {
        $currentV4 = @((Get-CurrentDns -Adapter $script:SelectedAdapter).IPv4)
        if ($currentV4.Count -gt 0) {
            $first = [string]$currentV4[0]
            $known = @($script:Providers.Values | ForEach-Object { $_.IPv4 })
            if ($first -and ($known -notcontains $first)) {
                $targets += [pscustomobject]@{ Name = "Current DNS"; Server = $first }
            }
        }
    }

    Write-Host ("Real ping benchmark: {0} resolvers, 1 ICMP ping + 1 DNS query per second each, {1} seconds." -f $targets.Count, $duration) -ForegroundColor Cyan
    Write-Host "All resolvers are tested at the same time. Pause downloads/streams for accurate results." -ForegroundColor DarkGray
    Write-Host ""

    $pool = [runspacefactory]::CreateRunspacePool(1, $targets.Count)
    $pool.Open()
    $jobs = @()
    $total = [Diagnostics.Stopwatch]::StartNew()
    try {
        foreach ($t in $targets) {
            $ps = [powershell]::Create()
            $ps.RunspacePool = $pool
            [void]$ps.AddScript($script:BenchmarkWorker.ToString())
            [void]$ps.AddArgument($t.Server)
            [void]$ps.AddArgument($duration)
            [void]$ps.AddArgument($timeoutMs)
            [void]$ps.AddArgument($domains)
            $handle = $ps.BeginInvoke()
            $jobs += [pscustomobject]@{ Target = $t; PowerShell = $ps; Handle = $handle }
        }

        while (@($jobs | Where-Object { -not $_.Handle.IsCompleted }).Count -gt 0) {
            $elapsed = [math]::Min($total.Elapsed.TotalSeconds, $duration)
            Write-Progress -Activity "DNS ping benchmark" `
                -Status ("{0:N0} s of {1} s" -f $elapsed, $duration) `
                -PercentComplete ([int](100 * $elapsed / $duration))
            Start-Sleep -Milliseconds 250
        }
        Write-Progress -Activity "DNS ping benchmark" -Completed

        $rows = @()
        foreach ($job in $jobs) {
            $raw = $null
            try {
                $raw = @($job.PowerShell.EndInvoke($job.Handle)) | Select-Object -Last 1
            } catch {
                $raw = $null
            }

            $pingValues = @()
            $dnsValues = @()
            $pingSent = 0
            $dnsSent = 0
            if ($raw) {
                $pingValues = @($raw.Ping | Where-Object { $null -ne $_ })
                $dnsValues = @($raw.Dns | Where-Object { $null -ne $_ })
                $pingSent = [int]$raw.PingSent
                $dnsSent = [int]$raw.DnsSent
            }

            $pingStats = Get-LatencyStats -Values $pingValues
            $dnsStats = Get-LatencyStats -Values $dnsValues
            $pingLoss = 100.0
            if ($pingSent -gt 0) { $pingLoss = 100.0 * ($pingSent - $pingValues.Count) / $pingSent }
            $dnsLoss = 100.0
            if ($dnsSent -gt 0) { $dnsLoss = 100.0 * ($dnsSent - $dnsValues.Count) / $dnsSent }

            # Ranking score (lower is better): average ping, +5 ms for every 1% packet loss.
            # If a resolver ignores ICMP, its median DNS reply time is used instead.
            $score = $null
            if ($null -ne $pingStats) { $score = $pingStats.Avg + ($pingLoss * 5) }
            elseif ($null -ne $dnsStats) { $score = $dnsStats.Median + ($dnsLoss * 5) }

            $rows += [pscustomobject]@{
                Name = $job.Target.Name; Server = $job.Target.Server; Score = $score
                PingStats = $pingStats; DnsStats = $dnsStats; PingLoss = $pingLoss
            }
        }
    }
    finally {
        Write-Progress -Activity "DNS ping benchmark" -Completed
        foreach ($job in $jobs) {
            try { if (-not $job.Handle.IsCompleted) { $job.PowerShell.Stop() } } catch { }
            try { $job.PowerShell.Dispose() } catch { }
        }
        try { $pool.Close(); $pool.Dispose() } catch { }
    }

    $answered = @($rows | Where-Object { $null -ne $_.Score })
    if ($answered.Count -eq 0) {
        Write-Host "No resolver answered. Check your internet connection, VPN or firewall (ICMP and UDP/53 must be allowed)." -ForegroundColor Red
        return
    }

    $sorted = @($rows | Sort-Object @{ Expression = { if ($null -eq $_.Score) { [double]::MaxValue } else { $_.Score } } })
    $display = @()
    $rank = 1
    foreach ($r in $sorted) {
        $pingS = $r.PingStats
        $dnsS = $r.DnsStats
        $avgText = "blocked"; $minText = "-"; $maxText = "-"; $jitterText = "-"; $lossText = "-"
        if ($null -ne $pingS) {
            $avgText = ConvertTo-MsText $pingS.Avg
            $minText = ConvertTo-MsText $pingS.Min
            $maxText = ConvertTo-MsText $pingS.Max
            $jitterText = ConvertTo-MsText $pingS.Jitter
            $lossText = ("{0:N1}" -f $r.PingLoss)
        }
        $dnsText = "fail"
        if ($null -ne $dnsS) { $dnsText = ConvertTo-MsText $dnsS.Median }
        $rankText = "-"
        if ($null -ne $r.Score) { $rankText = [string]$rank; $rank++ }

        $display += [pscustomobject]@{
            Rank = $rankText; Provider = $r.Name; Server = $r.Server
            Avg = $avgText; Min = $minText; Max = $maxText; Jitter = $jitterText
            "Loss%" = $lossText; DNS = $dnsText
        }
    }

    Write-Host ("Finished in {0:N1} seconds." -f $total.Elapsed.TotalSeconds) -ForegroundColor Green
    Write-Host ""
    $display | Format-Table -AutoSize | Out-Host
    Write-Host "Avg/Min/Max/Jitter = ICMP ping in ms | Loss% = lost pings | DNS = median UDP DNS reply time in ms" -ForegroundColor DarkGray

    $best = $sorted[0]
    if ($null -ne $best.PingStats) {
        Write-Host ("Fastest by ping: {0} ({1}) - {2} ms average." -f $best.Name, $best.Server, (ConvertTo-MsText $best.PingStats.Avg)) -ForegroundColor Green
    } else {
        Write-Host ("Fastest by DNS reply: {0} ({1})." -f $best.Name, $best.Server) -ForegroundColor Green
    }
    Write-Host "Ping measures the distance to the resolver, not website speed. Public resolvers use anycast," -ForegroundColor Yellow
    Write-Host "so results depend on your ISP routing and can change through the day. 'blocked' = no ICMP reply." -ForegroundColor Yellow
}

function Test-CurrentConnection {
    Write-Host "Testing the Windows DNS resolver..." -ForegroundColor Cyan
    try {
        $answer = @(Resolve-DnsName -Name "example.com" -Type A -DnsOnly -ErrorAction Stop)
        Write-Host "DNS lookup succeeded." -ForegroundColor Green
        $answer | Where-Object { $_.Type -eq "A" } | Select-Object -First 3 Name, IPAddress | Format-Table -AutoSize | Out-Host
    } catch {
        Write-Host "DNS lookup failed: $($_.Exception.Message)" -ForegroundColor Red
    }

    # FIX: Test-NetConnection can hang for 20+ seconds when blocked; use a 3 second limit.
    Write-Host "Testing TCP connectivity to 1.1.1.1 port 443..." -ForegroundColor Cyan
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect("1.1.1.1", 443, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne(3000, $false) -and $client.Connected) {
            Write-Host "TCP port 443 reachable." -ForegroundColor Green
        } else {
            Write-Host "TCP port 443 test failed. Internet access or firewall may be blocking it." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "TCP port 443 test failed: $($_.Exception.Message)" -ForegroundColor Yellow
    } finally {
        try { $client.Close() } catch { }
    }
}

function Reset-DnsAutomatic {
    if (-not $script:SelectedAdapter) { return }
    $confirm = Read-Host "Save a backup and reset IPv4/IPv6 DNS to automatic? (Y/N)"
    if ($confirm -notmatch '^[Yy]$') { return }
    try {
        Save-DnsBackup -Adapter $script:SelectedAdapter | Out-Null
        Set-DnsClientServerAddress -InterfaceIndex $script:SelectedAdapter.ifIndex -ResetServerAddresses -ErrorAction Stop
        Write-Host "IPv4 and IPv6 DNS reset to automatic/default." -ForegroundColor Green
        [void](Clear-DnsCacheSafe)
    } catch {
        Write-Host "DNS reset failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-MainMenu {
    while ($true) {
        Write-Header
        if (-not $script:SelectedAdapter) {
            Write-Host "No adapter selected." -ForegroundColor Yellow
        } else {
            Show-CurrentDns
            Write-Host ""
        }

        Write-Host " DNS PROVIDERS" -ForegroundColor Cyan
        Write-Host " 1. Cloudflare"
        Write-Host " 2. Google Public DNS"
        Write-Host " 3. AdGuard DNS"
        Write-Host " 4. Quad9"
        Write-Host " 5. OpenDNS"
        Write-Host " 6. Cloudflare Family (malware + adult-content filtering)"
        Write-Host ""
        Write-Host " TOOLS" -ForegroundColor Cyan
        Write-Host (" 7. Real ping benchmark (~{0} seconds)" -f $script:BenchmarkSeconds)
        Write-Host " 8. Test current DNS / internet connection"
        Write-Host " 9. Save DNS backup now"
        Write-Host "10. Restore DNS backup"
        Write-Host "11. Reset DNS to automatic (DHCP/default)"
        Write-Host "12. Flush DNS cache"
        Write-Host "13. Change network adapter"
        Write-Host "14. Exit"
        Write-Host ""
        $choice = Read-Host "Select an option"

        # FIX: any unexpected error inside an option is shown instead of closing the window.
        try {
            if ($choice -in @("1","2","3","4","5","6")) {
                if (-not $script:SelectedAdapter) { Write-Host "Select an adapter first." -ForegroundColor Yellow; Pause-Menu; continue }
                Set-DnsProvider -ProviderKey $choice
                Pause-Menu
            } elseif ($choice -eq "7") {
                Run-DnsBenchmark
                Pause-Menu
            } elseif ($choice -eq "8") {
                Test-CurrentConnection
                Pause-Menu
            } elseif ($choice -eq "9") {
                if ($script:SelectedAdapter) { Save-DnsBackup -Adapter $script:SelectedAdapter | Out-Null } else { Write-Host "Select an adapter first." -ForegroundColor Yellow }
                Pause-Menu
            } elseif ($choice -eq "10") {
                Restore-DnsBackup
                Pause-Menu
            } elseif ($choice -eq "11") {
                Reset-DnsAutomatic
                Pause-Menu
            } elseif ($choice -eq "12") {
                if (Clear-DnsCacheSafe) { Write-Host "DNS cache cleared." -ForegroundColor Green }
                Pause-Menu
            } elseif ($choice -eq "13") {
                Select-Adapter
            } elseif ($choice -eq "14") {
                return
            } else {
                Write-Host "Invalid option." -ForegroundColor Red
                Start-Sleep -Milliseconds 900
            }
        } catch {
            Write-Host ""
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Pause-Menu
        }
    }
}

# Entry point
# FIX: the script runs in its own elevated window; without this handler any unexpected
# error made that window vanish before the message could be read.
try {
    Ensure-Administrator
    if (-not (Get-Command Get-NetAdapter -ErrorAction SilentlyContinue)) {
        Write-Host "Required Windows networking cmdlets are unavailable. Use Windows 10/11 with PowerShell." -ForegroundColor Red
        Pause-Menu
        exit 1
    }
    if (-not (Test-Path $script:BackupDir)) {
        New-Item -ItemType Directory -Path $script:BackupDir -Force | Out-Null
    }
    Select-Adapter
    if ($script:SelectedAdapter) {
        Show-MainMenu
    } else {
        Write-Host "No adapter selected. Exiting." -ForegroundColor Yellow
        Start-Sleep -Seconds 2
    }
} catch {
    Write-Host ""
    Write-Host "Unexpected error: $($_.Exception.Message)" -ForegroundColor Red
    if ($_.ScriptStackTrace) { Write-Host $_.ScriptStackTrace -ForegroundColor DarkGray }
    Pause-Menu
    exit 1
}
