$projFile = "C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj"
$content = Get-Content $projFile -Raw

$baseDir = "C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios"
$swiftFiles = Get-ChildItem -Path $baseDir -Recurse -Filter "*.swift" | Where-Object { $_.Name -ne "NoviosApp.swift" }

$counter = 2
$refAddr = 0x3EA

$buildFileEntries = @()
$fileRefEntries = @()
$sourceFileEntries = @()
$groupChildEntries = @()
$addedCount = 0

foreach ($file in $swiftFiles) {
    $relPath = $file.DirectoryName.Replace($baseDir, "").TrimStart('\').Replace('\', '/')
    $fullPath = if ($relPath) { "$relPath/$($file.Name)" } else { $file.Name }
    $fileName = $file.Name
    
    if ($content -match [regex]::Escape($fullPath)) {
        continue
    }
    
    $fid = "9A$('{0:X5}' -f $counter)2C000000000000$('{0:X2}' -f $counter)"
    $rid = "9A$('{0:X5}' -f $refAddr)2C000000000000$('{0:X4}' -f $refAddr)"
    
    $buildFileEntries += "`t`t$fid /* $fileName in Sources */ = {isa = PBXBuildFile; fileRef = $rid /* $fileName */; };"
    $fileRefEntries += "`t`t$rid /* $fileName */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $fullPath; sourceTree = `"<group>`"; };"
    $sourceFileEntries += "`t`t`t`t$fid /* $fileName in Sources */,"
    $groupChildEntries += "`t`t`t`t$rid /* $fileName */,"
    
    $counter++
    $refAddr++
    $addedCount++
}

# 1. Insert SDKROOT in Debug config
$content = $content -replace '(9A9000002C00000000000000 /\* Debug \*/\s*=\s*\{\s*isa = XCBuildConfiguration;\s*buildSettings = \{\s*)', "`$1`t`t`t`tSDKROOT = iphoneos;`n"

# 2. Insert SDKROOT in Release config
$content = $content -replace '(9A9000012C00000000000000 /\* Release \*/\s*=\s*\{\s*isa = XCBuildConfiguration;\s*buildSettings = \{\s*)', "`$1`t`t`t`tSDKROOT = iphoneos;`n"

# 3. Insert build file entries AFTER the NoviosApp.swift build file entry (match the full entry including closing })
$content = $content -replace '(9A1000012C00000100000001 /\* NoviosApp\.swift in Sources \*/ = \{[^}]+?; \};)', "`$1`n$($buildFileEntries -join "`n")"

# 4. Insert file ref entries AFTER the Novios.app ref
$content = $content -replace '(9A2000002C00000000000000 /\* Novios\.app \*/ = \{[^}]+?\};)', "`$1`n$($fileRefEntries -join "`n")"

# 5. Insert source entries after NoviosApp.swift in Sources build phase file list
$content = $content -replace '(9A1000012C00000100000001 /\* NoviosApp\.swift in Sources \*/,)', "`$1`n$($sourceFileEntries -join "`n")"

# 6. Insert group children after NoviosApp.swift in the group (match with COMMA, which only appears in group)
$content = $content -replace '(9A2000012C00000100000001 /\* NoviosApp\.swift \*/,)', "`$1`n$($groupChildEntries -join "`n")"

Set-Content -Path $projFile -Value $content -NoNewline
Write-Host "Done - $addedCount files added (skipped $($swiftFiles.Count - $addedCount) existing)"
