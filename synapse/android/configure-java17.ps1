# PowerShell script to configure Java 17 for Gradle
# Run this script if Gradle keeps using Java 21

Write-Host "Configuring Gradle to use Java 17..." -ForegroundColor Green

# Stop all Gradle daemons
Write-Host "Stopping Gradle daemons..." -ForegroundColor Yellow
.\gradlew.bat --stop

# Check for Java 17 installations
Write-Host "`nChecking for Java 17 installations..." -ForegroundColor Yellow

$java17Paths = @(
    "C:\Program Files\Java\jdk-17",
    "C:\Program Files\Java\jdk-17.0.x",
    "$env:LOCALAPPDATA\Programs\Android\Android Studio\jbr-17",
    "$env:ProgramFiles\Android\Android Studio\jbr-17"
)

# Add JAVA_HOME if it's set and not empty
if ($env:JAVA_HOME -and $env:JAVA_HOME.Trim() -ne "") {
    $java17Paths += $env:JAVA_HOME
}

$foundJava17 = $null
foreach ($path in $java17Paths) {
    if (Test-Path $path) {
        $javaExe = Join-Path $path "bin\java.exe"
        if (Test-Path $javaExe) {
            $version = & $javaExe -version 2>&1 | Select-String "version"
            if ($version -match "17") {
                $foundJava17 = $path
                Write-Host "Found Java 17 at: $path" -ForegroundColor Green
                break
            }
        }
    }
}

if ($foundJava17) {
    # Update gradle.properties
    $gradleProps = "gradle.properties"
    $content = Get-Content $gradleProps -Raw
    
    # Remove old java.home line if exists
    $content = $content -replace "(?m)^org\.gradle\.java\.home=.*$", ""
    
    # Add new java.home line
    $newLine = "org.gradle.java.home=$foundJava17"
    
    if ($content -notmatch "org\.gradle\.java\.home") {
        $content += "`n$newLine`n"
    } else {
        $content = $content -replace "(?m)^(org\.gradle\.java\.home=.*)$", $newLine
    }
    
    Set-Content -Path $gradleProps -Value $content
    Write-Host "`nUpdated gradle.properties with Java 17 path!" -ForegroundColor Green
    Write-Host "Java 17 path: $foundJava17" -ForegroundColor Cyan
} else {
    Write-Host "`nJava 17 not found. Options:" -ForegroundColor Yellow
    Write-Host "1. Download Java 17 from: https://adoptium.net/temurin/releases/?version=17" -ForegroundColor Cyan
    Write-Host "2. Or let Gradle auto-download Java 17 on first build" -ForegroundColor Cyan
    Write-Host "`nGradle will attempt to download Java 17 automatically..." -ForegroundColor Yellow
}

Write-Host "`nConfiguration complete! Try running: flutter run" -ForegroundColor Green
