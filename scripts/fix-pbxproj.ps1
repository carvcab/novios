$projFile = "C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj"
$content = Get-Content $projFile -Raw

$swiftFiles = Get-ChildItem -Path "C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios" -Recurse -Filter "*.swift" | Where-Object { $_.Name -ne "NoviosApp.swift" }

$buildFileEntries = @()
$fileRefEntries = @()
$groupEntries = @{}
$sourceFileEntries = @()

$counter = 2
$refCounter = 0x3EA

function New-GroupId { "9A4000$('{0:X2}' -f (60 + $script:groupCounter))2C000000000000$('{0:X2}' -f (60 + $script:groupCounter))" }

$groupIdMap = @{}
$groupIdCounter = 0

foreach ($file in $swiftFiles) {
    $relDir = $file.DirectoryName.Replace("C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios\", "")
    $relDir = $relDir -replace '\\', '/'
    
    $fileId = "9A$('{0:X5}' -f $counter)2C000000000000$('{0:X2}' -f $counter)"
    $refId = "9A$('{0:X5}' -f $refCounter)2C000000000000$('{0:X4}' -f $refCounter)"
    
    $buildFileEntries += "`t`t$fileId /* $($file.Name) in Sources */ = {isa = PBXBuildFile; fileRef = $refId /* $($file.Name) */; };"
    $fileRefEntries += "`t`t$refId /* $($file.Name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $($file.Name); sourceTree = `"<group>`"; };"
    $sourceFileEntries += "`t`t`t`t$fileId /* $($file.Name) in Sources */,"
    
    $counter++
    $refCounter++
}

$buildFileBlock = "`n/* Begin PBXBuildFile section */`n$($buildFileEntries -join "`n")`n`n/* End PBXBuildFile section */`n"
$fileRefBlock = "`n/* Begin PBXFileReference section */`n$($fileRefEntries -join "`n")`n`n/* End PBXFileReference section */`n"

# Add SDKROOT to the Debug config at project level
$content = $content -replace '(9A9000002C00000000000000 \/\* Debug \*\/ = \{[^}]*?buildSettings = \{[^}]*?)(\};)', @"
`$1				SDKROOT = iphoneos;
			`$2
"@

# Add SDKROOT to Release config at project level  
$content = $content -replace '(9A9000012C00000000000000 \/\* Release \*\/ = \{[^}]*?buildSettings = \{[^}]*?)(\};)', @"
`$1				SDKROOT = iphoneos;
			`$2
"@

# Add the new build file entries AFTER existing ones
$content = $content -replace '(9A1000012C00000100000001 /\* NoviosApp\.swift in Sources \*/ = \{[^}]+?\};)', "`$1`n$($buildFileEntries -join "`n")"

# Add the new file reference entries AFTER existing ones
$content = $content -replace '(9A2000002C00000000000000 /\* Novios\.app \*/ = \{[^}]+?\};)', "`$1`n$($fileRefEntries -join "`n")"

# Add files to the Sources build phase AFTER existing entry
$content = $content -replace '(9A1000012C00000100000001 /\* NoviosApp\.swift in Sources \*/,)', "`$1`n$($sourceFileEntries -join "`n")"

Set-Content -Path $projFile -Value $content -NoNewline

Write-Host "Fixed project.pbxproj: added SDKROOT=iphoneos, $($swiftFiles.Count) source files"
