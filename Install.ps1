<#
.SYNOPSIS
Installs the Herdr app mods in this repository, all of them or the ones you name.

.DESCRIPTION
Every folder with a mods folder inside is one item, laid out like the Herdr
app's own folder. An item's mods are copied to the app's mods folder and the
keys in its keys.json are added to the app's keys.json. Idempotent,
non-elevated: run it again to update.

A mod's config.js holds what is yours (folders, names). It is copied once and
never overwritten.

.PARAMETER Mod
The items to install. What they need is installed with them. Without it,
the script lists the items and asks which you want.

.PARAMETER All
Install everything, with the borderless layout, without asking.

.PARAMETER Layout
Also install the borderless item: the layout with its Files, Changes and tab
bar. A block whose mod is not installed shows what stands in for it (the
shipped mod it was cloned from, borderless-tabs for timed-tabs) or is left out. Once the layout is there,
every install fits it again.

.PARAMETER Rebind
Let a mod take a key that already does something else. Without it such a key is
reported and left alone.

.PARAMETER Pull
Copy the other way: take the live files back into the repository, to commit
changes that were made in place. config.js files stay where they are.

.PARAMETER List
Show the items and what each needs, and install nothing.

.EXAMPLE
.\Install.ps1 agent-cards, pr-inbox -Layout
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string[]]$Mod,
    [switch]$All,
    [switch]$Layout,
    [switch]$Rebind,
    [switch]$Pull,
    [switch]$List
)

$ErrorActionPreference = 'Stop'

$needs = @{
    'shortcuts'     = @('timed-tabs')
    'run-configurations'    = @('timed-tabs')
    'space-folders' = @('project-picker')
}
$layoutItem = 'borderless'
$stands = @{ 'timed-tabs' = 'borderless-tabs' }
$personal = 'config.js'

$appHome = Join-Path $HOME '.config\herdr-app'
if ($env:HERDR_APP_HOME) { $appHome = $env:HERDR_APP_HOME }
$utf8 = New-Object System.Text.UTF8Encoding($false)

$items = @(Get-ChildItem -LiteralPath $PSScriptRoot -Directory |
    Where-Object { $_.Name -ne 'upstream' -and (Test-Path -LiteralPath (Join-Path $_.FullName 'mods')) } |
    ForEach-Object { $_.Name } | Sort-Object)

function Get-ItemMods([string]$Item) {
    return @(Get-ChildItem -LiteralPath (Join-Path $PSScriptRoot "$Item\mods") -Directory)
}

if ($List) {
    foreach ($item in $items) {
        $line = $item
        $mods = @(Get-ItemMods $item | ForEach-Object { $_.Name } | Where-Object { $_ -ne $item })
        if ($mods.Count) { $line += " (with $($mods -join ', '))" }
        if ($needs[$item]) { $line += ", needs $($needs[$item] -join ', ')" }
        if ($item -eq $layoutItem) { $line += ', the layout (-Layout)' }
        Write-Host $line
    }
    return
}

if (-not (Test-Path -LiteralPath $appHome)) {
    Write-Host "Herdr app not found ($appHome); nothing to install."
    return
}

function Test-Installed([string]$Item) {
    if ($Item -eq $layoutItem) { return Test-Path -LiteralPath (Join-Path $appHome "layouts\$layoutItem.json") }
    return Test-Path -LiteralPath (Join-Path $appHome "mods\$Item")
}

if (-not $Mod -and -not $All -and -not $Pull) {
    $installed = @($items | Where-Object { Test-Installed $_ })
    Write-Host 'Which do you want?'
    for ($i = 0; $i -lt $items.Count; $i++) {
        $line = '{0,3}  {1}' -f ($i + 1), $items[$i]
        if ($needs[$items[$i]]) { $line += ", with $($needs[$items[$i]] -join ', ')" }
        if ($items[$i] -eq $layoutItem) { $line += ', the layout' }
        if ($installed -contains $items[$i]) { $line += ' (installed)' }
        Write-Host $line
    }
    $onEnter = 'install nothing'
    if ($installed.Count) { $onEnter = 'update what is installed' }
    try {
        $answer = Read-Host "Numbers or names, separated by commas; 'all' for everything; Enter to $onEnter"
    } catch {
        Write-Host 'Cannot ask here. Name the items, or pass -All for everything.'
        return
    }
    $picks = @("$answer" -split '[,\s]+' | Where-Object { $_ })
    if (-not $picks.Count) {
        if (-not $installed.Count) {
            Write-Host 'Nothing installed.'
            return
        }
        $Mod = $installed
    } elseif ($picks -notcontains 'all') {
        $Mod = @($picks | ForEach-Object {
            $number = 0
            if ([int]::TryParse($_, [ref]$number) -and $number -ge 1 -and $number -le $items.Count) { $items[$number - 1] } else { $_ }
        })
    }
}

$chosen = $items
if ($Mod) {
    $unknown = @($Mod | Where-Object { $_ -notin $items })
    if ($unknown.Count) {
        Write-Host "Unknown: $($unknown -join ', '). Known: $($items -join ', ')."
        return
    }
    if ($Mod -contains $layoutItem) { $Layout = $true }
    $chosen = @()
    $queue = @($Mod)
    if ($Layout) { $queue += $layoutItem }
    while ($queue.Count) {
        $next = $queue[0]
        $queue = @($queue | Select-Object -Skip 1)
        if ($chosen -contains $next) { continue }
        $chosen += $next
        if ($needs[$next]) { $queue += $needs[$next] }
    }
    $chosen = @($chosen | Sort-Object)
} else {
    $Layout = $true
}

if (-not $Pull) { & (Join-Path $PSScriptRoot 'Merge-Upstream.ps1') }

function Test-Tracked([System.IO.FileInfo]$File) {
    return $File.Extension -in '.js', '.json', '.svg' -and $File.Name -ne 'jsconfig.json'
}

function Copy-Changed([string]$From, [string]$To) {
    $parent = Split-Path -Parent $To
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
    if ((Test-Path -LiteralPath $To) -and (Get-FileHash -LiteralPath $From).Hash -eq (Get-FileHash -LiteralPath $To).Hash) {
        Write-Host "unchanged  $To"
        return
    }
    Copy-Item -LiteralPath $From -Destination $To -Force
    Write-Host "copied     $To"
}

$created = @()
foreach ($item in $chosen) {
    foreach ($folder in Get-ItemMods $item) {
        $live = Join-Path $appHome "mods\$($folder.Name)"
        if ($Pull) {
            if (-not (Test-Path -LiteralPath $live)) {
                Write-Warning "Not installed, skipped: $live"
                continue
            }
            foreach ($file in Get-ChildItem -LiteralPath $live -File | Where-Object { (Test-Tracked $_) -and $_.Name -ne $personal }) {
                Copy-Changed $file.FullName (Join-Path $folder.FullName $file.Name)
            }
            continue
        }
        foreach ($file in Get-ChildItem -LiteralPath $folder.FullName -File | Where-Object { Test-Tracked $_ }) {
            $to = Join-Path $live $file.Name
            if ($file.Name -eq $personal -and (Test-Path -LiteralPath $to)) {
                Write-Host "kept       $to"
                continue
            }
            if ($file.Extension -in '.js', '.json' -and (Select-String -LiteralPath $file.FullName -Pattern '^<<<<<<< ' -Quiet)) {
                Write-Warning "Unresolved merge conflict, skipped: $($file.FullName)"
                continue
            }
            Copy-Changed $file.FullName $to
            if ($file.Name -eq $personal) { $created += $to }
        }
    }
}

function Get-CloneOrigin([string]$Name) {
    foreach ($item in $items) {
        $manifest = Join-Path $PSScriptRoot "$item\mods\$Name\mod.json"
        if (Test-Path -LiteralPath $manifest) {
            $from = ([System.IO.File]::ReadAllText($manifest) | ConvertFrom-Json).cloned_from
            if ($from) { return $from.name }
            return $null
        }
    }
    return $null
}

$script:fitted = @()
function Set-Fitting($Node) {
    if ($Node.content -and $Node.content.mod -and -not (Test-Path -LiteralPath (Join-Path $appHome "mods\$($Node.content.mod)"))) {
        $origin = $stands[$Node.content.mod]
        if (-not $origin) { $origin = Get-CloneOrigin $Node.content.mod }
        if (-not $origin) {
            $script:fitted += "left out $($Node.content.mod)"
            return $false
        }
        $script:fitted += "$origin for $($Node.content.mod)"
        $Node.content.mod = $origin
    }
    if ($Node.children) {
        $kept = @()
        foreach ($child in $Node.children) {
            if (Set-Fitting $child) { $kept += $child }
        }
        $Node.children = $kept
    }
    return $true
}

$repoLayout = Join-Path $PSScriptRoot "$layoutItem\layouts\$layoutItem.json"
$liveLayout = Join-Path $appHome "layouts\$layoutItem.json"
if (-not $Pull -and (Test-Path -LiteralPath $liveLayout)) { $Layout = $true }
if ($Layout) {
    $tree = [System.IO.File]::ReadAllText($repoLayout) | ConvertFrom-Json
    Set-Fitting $tree | Out-Null
    if ($Pull) {
        if ($script:fitted.Count) {
            Write-Host "skipped    $liveLayout (fitted to the installed mods: $($script:fitted -join ', '))"
        } elseif (Test-Path -LiteralPath $liveLayout) {
            Copy-Changed $liveLayout $repoLayout
        }
    } elseif (-not $script:fitted.Count) {
        Copy-Changed $repoLayout $liveLayout
    } else {
        $text = $tree | ConvertTo-Json -Depth 32
        if ((Test-Path -LiteralPath $liveLayout) -and [System.IO.File]::ReadAllText($liveLayout) -eq $text) {
            Write-Host "unchanged  $liveLayout"
        } else {
            New-Item -ItemType Directory -Path (Split-Path -Parent $liveLayout) -Force | Out-Null
            [System.IO.File]::WriteAllText($liveLayout, $text, $utf8)
            Write-Host "fitted     $liveLayout ($($script:fitted -join ', '))"
        }
    }
}

function Find-JsonMember([string]$Text, [int]$Open, [string]$Name) {
    $wanted = $Name | ConvertTo-Json
    $found = [pscustomobject]@{ Close = -1; Count = 0; Start = -1; End = -1 }
    $depth = 0
    $expectKey = $false
    $inWanted = $false
    $i = $Open
    while ($i -lt $Text.Length) {
        $c = $Text[$i]
        if ($c -eq '"') {
            $j = $i + 1
            while ($Text[$j] -ne '"') {
                if ($Text[$j] -eq '\') { $j++ }
                $j++
            }
            if ($depth -eq 1 -and $expectKey) {
                $expectKey = $false
                $found.Count++
                if ($Text.Substring($i, $j - $i + 1) -eq $wanted) {
                    $inWanted = $true
                    $k = $Text.IndexOf(':', $j) + 1
                    while ([char]::IsWhiteSpace($Text[$k])) { $k++ }
                    $found.Start = $k
                    $i = $k
                    continue
                }
            }
            $i = $j + 1
            continue
        }
        if ($c -eq '{' -or $c -eq '[') {
            $depth++
            if ($depth -eq 1) { $expectKey = $true }
        } elseif ($c -eq '}' -or $c -eq ']') {
            $depth--
            if ($depth -eq 0) {
                $found.Close = $i
                if ($inWanted) { $found.End = $i }
                break
            }
        } elseif ($c -eq ',' -and $depth -eq 1) {
            $expectKey = $true
            if ($inWanted) {
                $found.End = $i
                $inWanted = $false
            }
        }
        $i++
    }
    if ($found.End -ge 0) {
        while ([char]::IsWhiteSpace($Text[$found.End - 1])) { $found.End-- }
    }
    return $found
}

function Add-JsonMember([string]$Text, [int]$Open, [string]$Name, [string]$Value, [string]$Indent, [string]$Eol) {
    $object = Find-JsonMember $Text $Open $Name
    $last = $object.Close - 1
    while ([char]::IsWhiteSpace($Text[$last])) { $last-- }
    $tail = $Text.Substring($last + 1)
    if ($Text.Substring($last + 1, $object.Close - $last - 1) -notmatch "`n") { $tail = $Eol + $Indent.Substring(2) + $tail }
    $comma = ''
    if ($object.Count) { $comma = ',' }
    return $Text.Substring(0, $last + 1) + $comma + $Eol + $Indent + ($Name | ConvertTo-Json) + ': ' + $Value + $tail
}

$keysPath = Join-Path $appHome 'keys.json'
$taken = @()
if (-not $Pull -and (Test-Path -LiteralPath $keysPath)) {
    $keys = [System.IO.File]::ReadAllText($keysPath)
    $original = $keys
    $eol = "`n"
    if ($keys.Contains("`r`n")) { $eol = "`r`n" }
    foreach ($item in $chosen) {
        $fragment = Join-Path $PSScriptRoot "$item\keys.json"
        if (-not (Test-Path -LiteralPath $fragment)) { continue }
        $wanted = [System.IO.File]::ReadAllText($fragment) | ConvertFrom-Json
        foreach ($section in $wanted.PSObject.Properties) {
            foreach ($binding in $section.Value.PSObject.Properties) {
                $value = $binding.Value | ConvertTo-Json -Compress -Depth 8
                $root = $keys.IndexOf('{')
                $at = Find-JsonMember $keys $root $section.Name
                if ($at.Start -lt 0) {
                    $keys = Add-JsonMember $keys $root $section.Name '{}' '  ' $eol
                    $at = Find-JsonMember $keys $root $section.Name
                }
                $current = Find-JsonMember $keys $at.Start $binding.Name
                if ($current.Start -lt 0) {
                    $keys = Add-JsonMember $keys $at.Start $binding.Name $value '    ' $eol
                    Write-Host "bound      $($binding.Name) to $value ($($section.Name))"
                    continue
                }
                $existing = $keys.Substring($current.Start, $current.End - $current.Start)
                if (($existing | ConvertFrom-Json | ConvertTo-Json -Compress -Depth 8) -eq $value) { continue }
                if (-not $Rebind) {
                    $taken += "$($binding.Name) is $existing; $item wants $value"
                    continue
                }
                $keys = $keys.Substring(0, $current.Start) + $value + $keys.Substring($current.End)
                Write-Host "rebound    $($binding.Name) from $existing to $value ($($section.Name))"
            }
        }
    }
    if ($keys -ne $original) {
        $valid = $true
        try { $keys | ConvertFrom-Json | Out-Null } catch { $valid = $false }
        if ($valid) {
            [System.IO.File]::WriteAllText($keysPath, $keys, $utf8)
        } else {
            Write-Warning "Could not add the keys to $keysPath without breaking it; left as it was. Add them by hand from each item's keys.json."
        }
    }
}

if ($Pull) { return }

Write-Host ''
foreach ($path in $created) { Write-Host "Yours to fill in: $path" }
if ($taken.Count) {
    Write-Warning 'These keys already do something else and were left alone. Run again with -Rebind to hand them to the mods:'
    foreach ($line in $taken) { Write-Warning "  $line" }
}
if ($Layout) {
    Write-Host "Files apply at once. Show the layout with: herdr-app do layout.switch --name $layoutItem"
} else {
    Write-Host 'Files apply at once. A mod shows where a layout puts it: add -Layout for the borderless layout,'
    Write-Host 'or point a block of your own layout at the mod ("content": { "mod": "<name>" }).'
}
