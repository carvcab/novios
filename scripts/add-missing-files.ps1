$projFile = "C:\Users\diego\Documents\Nueva carpeta\iphone app\Novios.xcodeproj\project.pbxproj"

# Read with correct line endings
$content = [System.IO.File]::ReadAllText($projFile)

$files = @(
    @{name="CollectionsView.swift"; path="Views/Love/CollectionsView.swift"},
    @{name="CompatibilityView.swift"; path="Views/Love/CompatibilityView.swift"},
    @{name="CustomQuizView.swift"; path="Views/Love/CustomQuizView.swift"},
    @{name="DiceView.swift"; path="Views/Love/DiceView.swift"},
    @{name="HangmanView.swift"; path="Views/Love/HangmanView.swift"},
    @{name="LoveGameView.swift"; path="Views/Love/LoveGameView.swift"},
    @{name="NeverHaveIEverView.swift"; path="Views/Love/NeverHaveIEverView.swift"},
    @{name="RouletteView.swift"; path="Views/Love/RouletteView.swift"},
    @{name="TruthOrDareCustomView.swift"; path="Views/Love/TruthOrDareCustomView.swift"},
    @{name="WouldYouRatherView.swift"; path="Views/Love/WouldYouRatherView.swift"},
    @{name="AIMemoryService.swift"; path="Services/AIMemoryService.swift"},
    @{name="AIModelManager.swift"; path="Services/AIModelManager.swift"},
    @{name="GameService.swift"; path="Services/GameService.swift"},
    @{name="SharedNotificationService.swift"; path="Services/SharedNotificationService.swift"},
    @{name="AIAssistantOverlay.swift"; path="Views/AI/AIAssistantOverlay.swift"},
    @{name="AIDownloadView.swift"; path="Views/AI/AIDownloadView.swift"},
    @{name="LocationModels.swift"; path="Views/Location/LocationModels.swift"}
)

$nl = "`r`n"
$tab = "`t"

$buildFileEntries = @()
$fileRefEntries = @()
$sourceFileEntries = @()
$groupChildEntries = @()

$idx = 0
foreach ($f in $files) {
    $buildId = "9A006{0:X3}2C0000000000006{1:X2}" -f (0x200 + $idx), (0x00 + $idx)
    $refId = "9A006{0:X3}2C0000000000006{1:X3}" -f (0x300 + $idx), (0x100 + $idx)
    
    $buildFileEntries += "$tab$tab$buildId /* $($f.name) in Sources */ = {isa = PBXBuildFile; fileRef = $refId /* $($f.name) */; };"
    $fileRefEntries += "$tab$tab$refId /* $($f.name) */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = $($f.path); sourceTree = `"<group>`"; };"
    $sourceFileEntries += "$tab$tab$tab$tab$buildId /* $($f.name) in Sources */,"
    $groupChildEntries += "$tab$tab$tab$tab$refId /* $($f.name) */,"
    
    $idx++
}

# 1. Insert build file entries before "/* End PBXBuildFile section */"
$content = $content.Replace("/* End PBXBuildFile section */", ($buildFileEntries -join $nl) + "$nl`t/* End PBXBuildFile section */")

# 2. Insert file ref entries before "/* End PBXFileReference section */"
$content = $content.Replace("/* End PBXFileReference section */", ($fileRefEntries -join $nl) + "$nl`t/* End PBXFileReference section */")

# 3. Insert group children after the last MoreView.swift child
$groupLastLine = "$tab$tab$tab$tab" + "9A0050V2C000000000000085 /* MoreView.swift */,"
$content = $content.Replace($groupLastLine + $nl, $groupLastLine + $nl + ($groupChildEntries -join $nl) + $nl)

# 4. Insert source entries after the last MoreView.swift source entry
$srcLastLine = "$tab$tab$tab$tab" + "9A0050W2C000000000000085 /* MoreView.swift in Sources */,"
$content = $content.Replace($srcLastLine + $nl, $srcLastLine + $nl + ($sourceFileEntries -join $nl) + $nl)

[System.IO.File]::WriteAllText($projFile, $content)
Write-Host "Done - $($files.Count) files added"
