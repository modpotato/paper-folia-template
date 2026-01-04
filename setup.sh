#!/bin/bash

# Paper/Folia Plugin Template Setup Script
# This script will configure your plugin with custom names and information

set -e

# =========================================
# Sanitization and Validation Functions
# =========================================

# Sanitize a string into a valid Java identifier segment
# - Removes leading/trailing whitespace
# - Replaces spaces and invalid chars with nothing
# - Ensures it starts with a letter (prepends 'x' if needed)
# - Converts to lowercase for package names
sanitize_java_identifier() {
    local input="$1"
    local lowercase="${2:-true}"
    
    # Trim leading/trailing whitespace
    input=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Remove all characters that are not alphanumeric or underscore
    input=$(echo "$input" | sed 's/[^a-zA-Z0-9_]//g')
    
    # Ensure it starts with a letter (prepend 'x' if starts with digit or underscore)
    if [[ "$input" =~ ^[^a-zA-Z] ]]; then
        input="x$input"
    fi
    
    # Convert to lowercase if requested
    if [[ "$lowercase" == "true" ]]; then
        input=$(echo "$input" | tr '[:upper:]' '[:lower:]')
    fi
    
    echo "$input"
}

# Validate and sanitize a Java package group (e.g., com.example)
# Each segment must be a valid Java identifier
sanitize_java_group() {
    local input="$1"
    local result=""
    
    # Trim leading/trailing whitespace
    input=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    # Split by dots and sanitize each segment
    IFS='.' read -ra segments <<< "$input"
    for segment in "${segments[@]}"; do
        local sanitized
        sanitized=$(sanitize_java_identifier "$segment" "true")
        if [[ -n "$sanitized" ]]; then
            if [[ -n "$result" ]]; then
                result="$result.$sanitized"
            else
                result="$sanitized"
            fi
        fi
    done
    
    # If empty, use a default
    if [[ -z "$result" ]]; then
        result="com.example"
    fi
    
    echo "$result"
}

# Escape special characters for sed replacement strings
# Escapes: & \ / and newlines
escape_sed_replacement() {
    local input="$1"
    # Escape backslashes first, then &, then /
    echo "$input" | sed -e 's/\\/\\\\/g' -e 's/&/\\&/g' -e 's|/|\\/|g'
}

# Escape special characters for sed patterns (basic regex)
# Escapes: \ . * [ ] ^ $ /
escape_sed_pattern() {
    local input="$1"
    echo "$input" | sed -e 's/\\/\\\\/g' -e 's/\./\\./g' -e 's/\*/\\*/g' -e 's/\[/\\[/g' -e 's/\]/\\]/g' -e 's/\^/\\^/g' -e 's/\$/\\$/g' -e 's|/|\\/|g'
}

echo "========================================="
echo "Paper/Folia Plugin Template Setup"
echo "========================================="
echo ""

# Get plugin information from user
read -p "Enter your plugin name (e.g., MyAwesomePlugin): " PLUGIN_NAME_RAW
read -p "Enter plugin description: " PLUGIN_DESC
read -p "Enter plugin version [INDEV]: " PLUGIN_VERSION
PLUGIN_VERSION=${PLUGIN_VERSION:-INDEV}
read -p "Enter author name: " PLUGIN_AUTHOR
read -p "Enter group/package (e.g., com.example): " PLUGIN_GROUP_RAW
read -p "Enter GitHub repository (owner/repo) [leave blank to disable check]: " GITHUB_REPO

# Sanitize plugin name for use in Java identifiers
PLUGIN_NAME=$(sanitize_java_identifier "$PLUGIN_NAME_RAW" "false")
# Create display name (preserve original for display purposes, but sanitize for safety)
PLUGIN_DISPLAY_NAME=$(echo "$PLUGIN_NAME_RAW" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
# Convert sanitized plugin name to lowercase for package name
PLUGIN_PACKAGE=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]')
# Sanitize group/package
PLUGIN_GROUP=$(sanitize_java_group "$PLUGIN_GROUP_RAW")

# Validate that we have usable values
if [[ -z "$PLUGIN_NAME" ]]; then
    echo "Error: Plugin name could not be sanitized to a valid Java identifier."
    exit 1
fi

if [[ -z "$PLUGIN_PACKAGE" ]]; then
    echo "Error: Plugin package could not be generated."
    exit 1
fi

# Confirm details
echo ""
echo "========================================="
echo "Configuration Summary:"
echo "========================================="
echo "Plugin Name:    $PLUGIN_NAME (sanitized from: $PLUGIN_NAME_RAW)"
echo "Description:    $PLUGIN_DESC"
echo "Version:        $PLUGIN_VERSION"
echo "Author:         $PLUGIN_AUTHOR"
echo "Group:          $PLUGIN_GROUP (sanitized from: $PLUGIN_GROUP_RAW)"
echo "Package:        $PLUGIN_GROUP.$PLUGIN_PACKAGE"
if [[ -n $GITHUB_REPO ]]; then
    echo "Repo Check:     $GITHUB_REPO"
else
    echo "Repo Check:     disabled"
fi
echo ""
read -p "Is this correct? (y/n): " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

echo ""
echo "Configuring plugin..."

# Prepare escaped strings for sed replacements
ESCAPED_GROUP_PACKAGE=$(escape_sed_replacement "$PLUGIN_GROUP.$PLUGIN_PACKAGE")
ESCAPED_VERSION=$(escape_sed_replacement "$PLUGIN_VERSION")
ESCAPED_DESC=$(escape_sed_replacement "$PLUGIN_DESC")
ESCAPED_AUTHOR=$(escape_sed_replacement "$PLUGIN_AUTHOR")
ESCAPED_PLUGIN_NAME=$(escape_sed_replacement "$PLUGIN_NAME")
ESCAPED_GITHUB_REPO=$(escape_sed_replacement "$GITHUB_REPO")

# Update gradle.properties
echo "Updating gradle.properties..."
sed -i "/^# Plugin settings/,/^# Dependency versions/ s|^group=.*|group=$ESCAPED_GROUP_PACKAGE|" gradle.properties
sed -i "/^# Plugin settings/,/^# Dependency versions/ s|^version=.*|version=$ESCAPED_VERSION|" gradle.properties
sed -i "/^# Plugin settings/,/^# Dependency versions/ s|^description=.*|description=$ESCAPED_DESC|" gradle.properties
sed -i "/^# Plugin settings/,/^# Dependency versions/ s|^author=.*|author=$ESCAPED_AUTHOR|" gradle.properties

# Update settings.gradle.kts
echo "Updating settings.gradle.kts..."
sed -i "s|rootProject.name = \".*\"|rootProject.name = \"$ESCAPED_PLUGIN_NAME\"|g" settings.gradle.kts

# Update build.gradle.kts
echo "Updating build.gradle.kts..."
sed -i "s|application.mainClass = \".*\"|application.mainClass = \"$ESCAPED_GROUP_PACKAGE.Main\"|g" build.gradle.kts
sed -i "s|relocate(\"com.tcoded.folialib\", \"\${project.property(\"group\")}.lib.folialib\")|relocate(\"com.tcoded.folialib\", \"$ESCAPED_GROUP_PACKAGE.lib.folialib\")|g" build.gradle.kts

# Update plugin.yml
echo "Updating plugin.yml..."
sed -i "s|main: .*|main: $ESCAPED_GROUP_PACKAGE.Main|g" src/main/resources/plugin.yml

# Update GitHub Actions workflow
WORKFLOW_FILE=".github/workflows/build.yml"
if [[ -f $WORKFLOW_FILE ]]; then
    echo "Updating GitHub Actions workflow..."
    if [[ -n $GITHUB_REPO ]]; then
        sed -i "s|if: github.repository == '.*'|if: github.repository == '$ESCAPED_GITHUB_REPO'|g" "$WORKFLOW_FILE"
    else
        sed -i "/^[[:space:]]*if: github.repository == '.*'/d" "$WORKFLOW_FILE"
    fi
    sed -i "s|name: PluginNameHere-\${{ env.VERSION }}|name: $ESCAPED_PLUGIN_NAME-\${{ env.VERSION }}|g" "$WORKFLOW_FILE"
fi

# Create new directory structure
echo "Refactoring directory structure..."
NEW_DIR="src/main/java/$(echo $PLUGIN_GROUP | tr '.' '/')/$PLUGIN_PACKAGE"
mkdir -p "$NEW_DIR"

# Update Main.java package declaration and move it
echo "Updating Main.java..."
sed "s|package dev.modpotato.PESCAPED_luginNameHere;|package $PLUGIN_GROUP.$PLUGIN_PACKAGE;|g" src/main/java/dev/modpotato/PluginNameHere/Main.java > "$NEW_DIR/Main.java"

# Remove old directory structure
echo "Cleaning up old directory structure..."
rm -rf src/main/java/dev

# Update README.md
echo "Updating README.md..."
sed -i "s|# PluginNameHere|# $PLUGIN_NAME|g" README.md

echo ""
echo "========================================="
echo "Setup Complete!"
echo "========================================="
echo ""
echo "Your plugin has been configured successfully."
echo "Next steps:"
echo "1. Review the generated files"
echo "2. Run './gradlew build' to build your plugin"
echo "3. Run './gradlew runServer' to test your plugin"
echo ""
echo "Happy coding!"
