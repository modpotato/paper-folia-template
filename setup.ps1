# Paper/Folia Plugin Template Setup Script
# This script will configure your plugin with custom names and information

$ErrorActionPreference = "Stop"

# =========================================
# Sanitization and Validation Functions
# =========================================

# Sanitize a string into a valid Java identifier segment
# - Removes leading/trailing whitespace
# - Replaces spaces and invalid chars with nothing
# - Ensures it starts with a letter (prepends 'x' if needed)
# - Optionally converts to lowercase for package names
function Sanitize-JavaIdentifier {
    param(
        [string]$Input,
        [bool]$ToLowerCase = $true
    )
    
    # Trim leading/trailing whitespace
    $result = $Input.Trim()
    
    # Remove all characters that are not alphanumeric or underscore
    $result = $result -replace '[^a-zA-Z0-9_]', ''
    
    # Ensure it starts with a letter (prepend 'x' if starts with digit or underscore)
    if ($result -match '^[^a-zA-Z]') {
        $result = "x$result"
    }
    
    # Convert to lowercase if requested
    if ($ToLowerCase) {
        $result = $result.ToLower()
    }
    
    return $result
}

# Validate and sanitize a Java package group (e.g., com.example)
# Each segment must be a valid Java identifier
function Sanitize-JavaGroup {
    param(
        [string]$Input
    )
    
    # Trim leading/trailing whitespace
    $trimmed = $Input.Trim()
    
    # Split by dots and sanitize each segment
    $segments = $trimmed.Split('.')
    $resultSegments = @()
    
    foreach ($segment in $segments) {
        $sanitized = Sanitize-JavaIdentifier -Input $segment -ToLowerCase $true
        if (-not [string]::IsNullOrWhiteSpace($sanitized)) {
            $resultSegments += $sanitized
        }
    }
    
    # If empty, use a default
    if ($resultSegments.Count -eq 0) {
        return "com.example"
    }
    
    return $resultSegments -join '.'
}

# Escape special characters for PowerShell regex patterns
# Escapes: \ . * + ? [ ] ( ) { } ^ $ | 
function Escape-RegexPattern {
    param(
        [string]$Input
    )
    return [regex]::Escape($Input)
}

# Escape special characters for PowerShell regex replacement strings
# In PowerShell -replace, $ and \ have special meaning in replacement
function Escape-RegexReplacement {
    param(
        [string]$Input
    )
    # Escape $ as $$ and \ as \\
    $result = $Input -replace '\$', '$$$$'
    return $result
}

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Paper/Folia Plugin Template Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get plugin information from user
$PLUGIN_NAME_RAW = Read-Host "Enter your plugin name (e.g., MyAwesomePlugin)"
$PLUGIN_DESC = Read-Host "Enter plugin description"
$PLUGIN_VERSION = Read-Host "Enter plugin version [INDEV]"
if ([string]::IsNullOrWhiteSpace($PLUGIN_VERSION)) {
    $PLUGIN_VERSION = "INDEV"
}
$PLUGIN_AUTHOR = Read-Host "Enter author name"
$PLUGIN_GROUP_RAW = Read-Host "Enter group/package (e.g., com.example)"
$GITHUB_REPO = Read-Host "Enter GitHub repository (owner/repo) [leave blank to disable check]"

# Sanitize plugin name for use in Java identifiers (preserve case for display)
$PLUGIN_NAME = Sanitize-JavaIdentifier -Input $PLUGIN_NAME_RAW -ToLowerCase $false
# Convert sanitized plugin name to lowercase for package name
$PLUGIN_PACKAGE = $PLUGIN_NAME.ToLower()
# Sanitize group/package
$PLUGIN_GROUP = Sanitize-JavaGroup -Input $PLUGIN_GROUP_RAW

# Validate that we have usable values
if ([string]::IsNullOrWhiteSpace($PLUGIN_NAME)) {
    Write-Host "Error: Plugin name could not be sanitized to a valid Java identifier." -ForegroundColor Red
    exit 1
}

if ([string]::IsNullOrWhiteSpace($PLUGIN_PACKAGE)) {
    Write-Host "Error: Plugin package could not be generated." -ForegroundColor Red
    exit 1
}

# Confirm details
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Plugin Name:    $PLUGIN_NAME (sanitized from: $PLUGIN_NAME_RAW)" -ForegroundColor White
Write-Host "Description:    $PLUGIN_DESC" -ForegroundColor White
Write-Host "Version:        $PLUGIN_VERSION" -ForegroundColor White
Write-Host "Author:         $PLUGIN_AUTHOR" -ForegroundColor White
Write-Host "Group:          $PLUGIN_GROUP (sanitized from: $PLUGIN_GROUP_RAW)" -ForegroundColor White
Write-Host "Package:        $PLUGIN_GROUP.$PLUGIN_PACKAGE" -ForegroundColor White
if ([string]::IsNullOrWhiteSpace($GITHUB_REPO)) {
    Write-Host "Repo Check:     disabled" -ForegroundColor White
} else {
    Write-Host "Repo Check:     $GITHUB_REPO" -ForegroundColor White
}
Write-Host ""
$CONFIRM = Read-Host "Is this correct? (y/n)"

if ($CONFIRM -notmatch '^[Yy]$') {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configuring plugin..." -ForegroundColor Green

# Prepare escaped strings for regex replacements
$ESCAPED_GROUP_PACKAGE = Escape-RegexReplacement -Input "$PLUGIN_GROUP.$PLUGIN_PACKAGE"
$ESCAPED_PLUGIN_NAME = Escape-RegexReplacement -Input $PLUGIN_NAME
$ESCAPED_DESC = Escape-RegexReplacement -Input $PLUGIN_DESC
$ESCAPED_AUTHOR = Escape-RegexReplacement -Input $PLUGIN_AUTHOR
$ESCAPED_VERSION = Escape-RegexReplacement -Input $PLUGIN_VERSION
$ESCAPED_GITHUB_REPO = Escape-RegexReplacement -Input $GITHUB_REPO

# Update gradle.properties
Write-Host "Updating gradle.properties..." -ForegroundColor Yellow
$gradleProps = Get-Content "gradle.properties"
for ($i = 0; $i -lt $gradleProps.Length; $i++) {
    if ($gradleProps[$i] -match '^# Plugin settings') {
        # Found plugin settings section, update the next few lines
        for ($j = $i + 1; $j -lt $gradleProps.Length; $j++) {
            if ($gradleProps[$j] -match '^# Dependency versions') {
                break
            }
            if ($gradleProps[$j] -match '^group=') {
                $gradleProps[$j] = "group=$PLUGIN_GROUP.$PLUGIN_PACKAGE"
            }
            elseif ($gradleProps[$j] -match '^version=') {
                $gradleProps[$j] = "version=$PLUGIN_VERSION"
            }
            elseif ($gradleProps[$j] -match '^description=') {
                $gradleProps[$j] = "description=$PLUGIN_DESC"
            }
            elseif ($gradleProps[$j] -match '^author=') {
                $gradleProps[$j] = "author=$PLUGIN_AUTHOR"
            }
        }
        break
    }
}
$gradleProps | Set-Content "gradle.properties"

# Update settings.gradle.kts
Write-Host "Updating settings.gradle.kts..." -ForegroundColor Yellow
$settingsGradle = Get-Content "settings.gradle.kts" -Raw
$settingsGradle = $settingsGradle -replace 'rootProject\.name = ".*"', "rootProject.name = `"$ESCAPED_PLUGIN_NAME`""
Set-Content "settings.gradle.kts" -Value $settingsGradle -NoNewline

# Update build.gradle.kts
Write-Host "Updating build.gradle.kts..." -ForegroundColor Yellow
$buildGradle = Get-Content "build.gradle.kts" -Raw
$buildGradle = $buildGradle -replace 'application\.mainClass = ".*"', "application.mainClass = `"$ESCAPED_GROUP_PACKAGE.Main`""
$escapedRelocatePattern = Escape-RegexPattern -Input 'relocate("com.tcoded.folialib", "${project.property("group")}.lib.folialib")'
$buildGradle = $buildGradle -replace $escapedRelocatePattern, "relocate(`"com.tcoded.folialib`", `"$ESCAPED_GROUP_PACKAGE.lib.folialib`")"
Set-Content "build.gradle.kts" -Value $buildGradle -NoNewline

# Update plugin.yml
Write-Host "Updating plugin.yml..." -ForegroundColor Yellow
$pluginYml = Get-Content "src\main\resources\plugin.yml" -Raw
$pluginYml = $pluginYml -replace 'main: .*', "main: $ESCAPED_GROUP_PACKAGE.Main"
Set-Content "src\main\resources\plugin.yml" -Value $pluginYml -NoNewline

# Update GitHub Actions workflow
$workflowPath = ".github/workflows/build.yml"
if (Test-Path $workflowPath) {
    Write-Host "Updating GitHub Actions workflow..." -ForegroundColor Yellow
    $workflowLines = Get-Content $workflowPath
    $updatedWorkflow = @()
    foreach ($line in $workflowLines) {
        if ($line -match '^\s*if:\s+github\.repository ==') {
            if (-not [string]::IsNullOrWhiteSpace($GITHUB_REPO)) {
                $updatedWorkflow += "    if: github.repository == '$GITHUB_REPO'"
            }
            continue
        }
        if ($line -match '^\s*name:\s*PluginNameHere-\$\{\{ env\.VERSION \}\}') {
            $updatedWorkflow += "        name: $PLUGIN_NAME-" + '${{ env.VERSION }}'
            continue
        }
        $updatedWorkflow += $line
    }
    $updatedWorkflow | Set-Content $workflowPath
}
escapedOldPackage = Escape-RegexPattern -Input 'package dev.modpotato.PluginNameHere;'
$mainJava = $mainJava -replace $escapedOldPackage, "package $ESCAPED_GROUP
# Create new directory structure
Write-Host "Refactoring directory structure..." -ForegroundColor Yellow
$NEW_DIR = "src\main\java\$($PLUGIN_GROUP.Replace('.', '\'))\$PLUGIN_PACKAGE"
New-Item -ItemType Directory -Path $NEW_DIR -Force | Out-Null

# Update Main.java package declaration and move it
Write-Host "Updating Main.java..." -ForegroundColor Yellow
$mainJava = Get-Content "src\main\java\dev\modpotato\PluginNameHere\Main.java" -Raw
$escapedReadmePattern = Escape-RegexPattern -Input '# PluginNameHere'
$readme = $readme -replace $escapedReadmePattern, "# $ESCAPED_ato\.PluginNameHere;', "package $PLUGIN_GROUP.$PLUGIN_PACKAGE;"
Set-Content "$NEW_DIR\Main.java" -Value $mainJava -NoNewline

# Remove old directory structure
Write-Host "Cleaning up old directory structure..." -ForegroundColor Yellow
Remove-Item "src\main\java\dev" -Recurse -Force

# Update README.md
Write-Host "Updating README.md..." -ForegroundColor Yellow
$readme = Get-Content "README.md" -Raw
$readme = $readme -replace '# PluginNameHere', "# $PLUGIN_NAME"
Set-Content "README.md" -Value $readme -NoNewline

Write-Host ""
Write-Host "=========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Your plugin has been configured successfully." -ForegroundColor White
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Review the generated files" -ForegroundColor White
Write-Host "2. Run '.\gradlew.bat build' to build your plugin" -ForegroundColor White
Write-Host "3. Run '.\gradlew.bat runServer' to test your plugin" -ForegroundColor White
Write-Host ""
Write-Host "Happy coding!" -ForegroundColor Cyan
