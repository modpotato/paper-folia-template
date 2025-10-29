# Paper/Folia Plugin Template Setup Script
# This script will configure your plugin with custom names and information

$ErrorActionPreference = "Stop"

Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Paper/Folia Plugin Template Setup" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Get plugin information from user
$PLUGIN_NAME = Read-Host "Enter your plugin name (e.g., MyAwesomePlugin)"
$PLUGIN_DESC = Read-Host "Enter plugin description"
$PLUGIN_VERSION = Read-Host "Enter plugin version [INDEV]"
if ([string]::IsNullOrWhiteSpace($PLUGIN_VERSION)) {
    $PLUGIN_VERSION = "INDEV"
}
$PLUGIN_AUTHOR = Read-Host "Enter author name"
$PLUGIN_GROUP = Read-Host "Enter group/package (e.g., com.example)"

# Convert plugin name to lowercase for package name
$PLUGIN_PACKAGE = $PLUGIN_NAME.ToLower()

# Confirm details
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Configuration Summary:" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "Plugin Name:    $PLUGIN_NAME" -ForegroundColor White
Write-Host "Description:    $PLUGIN_DESC" -ForegroundColor White
Write-Host "Version:        $PLUGIN_VERSION" -ForegroundColor White
Write-Host "Author:         $PLUGIN_AUTHOR" -ForegroundColor White
Write-Host "Group:          $PLUGIN_GROUP" -ForegroundColor White
Write-Host "Package:        $PLUGIN_GROUP.$PLUGIN_PACKAGE" -ForegroundColor White
Write-Host ""
$CONFIRM = Read-Host "Is this correct? (y/n)"

if ($CONFIRM -notmatch '^[Yy]$') {
    Write-Host "Setup cancelled." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Configuring plugin..." -ForegroundColor Green

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
$settingsGradle = $settingsGradle -replace 'rootProject\.name = ".*"', "rootProject.name = `"$PLUGIN_NAME`""
Set-Content "settings.gradle.kts" -Value $settingsGradle -NoNewline

# Update build.gradle.kts
Write-Host "Updating build.gradle.kts..." -ForegroundColor Yellow
$buildGradle = Get-Content "build.gradle.kts" -Raw
$buildGradle = $buildGradle -replace 'application\.mainClass = ".*"', "application.mainClass = `"$PLUGIN_GROUP.$PLUGIN_PACKAGE.Main`""
$buildGradle = $buildGradle -replace 'relocate\("com\.tcoded\.folialib", "\$\{project\.property\("group"\)\}\.lib\.folialib"\)', "relocate(`"com.tcoded.folialib`", `"$PLUGIN_GROUP.$PLUGIN_PACKAGE.lib.folialib`")"
Set-Content "build.gradle.kts" -Value $buildGradle -NoNewline

# Update plugin.yml
Write-Host "Updating plugin.yml..." -ForegroundColor Yellow
$pluginYml = Get-Content "src\main\resources\plugin.yml" -Raw
$pluginYml = $pluginYml -replace 'main: .*', "main: $PLUGIN_GROUP.$PLUGIN_PACKAGE.Main"
Set-Content "src\main\resources\plugin.yml" -Value $pluginYml -NoNewline

# Create new directory structure
Write-Host "Refactoring directory structure..." -ForegroundColor Yellow
$NEW_DIR = "src\main\java\$($PLUGIN_GROUP.Replace('.', '\'))\$PLUGIN_PACKAGE"
New-Item -ItemType Directory -Path $NEW_DIR -Force | Out-Null

# Update Main.java package declaration and move it
Write-Host "Updating Main.java..." -ForegroundColor Yellow
$mainJava = Get-Content "src\main\java\dev\modpotato\PluginNameHere\Main.java" -Raw
$mainJava = $mainJava -replace 'package dev\.modpotato\.PluginNameHere;', "package $PLUGIN_GROUP.$PLUGIN_PACKAGE;"
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
