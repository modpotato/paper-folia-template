#!/bin/bash

# Paper/Folia Plugin Template Setup Script
# This script will configure your plugin with custom names and information

set -e

echo "========================================="
echo "Paper/Folia Plugin Template Setup"
echo "========================================="
echo ""

# Get plugin information from user
read -p "Enter your plugin name (e.g., MyAwesomePlugin): " PLUGIN_NAME
read -p "Enter plugin description: " PLUGIN_DESC
read -p "Enter plugin version [1.0.0]: " PLUGIN_VERSION
PLUGIN_VERSION=${PLUGIN_VERSION:-1.0.0}
read -p "Enter author name: " PLUGIN_AUTHOR
read -p "Enter group/package (e.g., com.example): " PLUGIN_GROUP

# Convert plugin name to lowercase for package name
PLUGIN_PACKAGE=$(echo "$PLUGIN_NAME" | tr '[:upper:]' '[:lower:]')

# Confirm details
echo ""
echo "========================================="
echo "Configuration Summary:"
echo "========================================="
echo "Plugin Name:    $PLUGIN_NAME"
echo "Description:    $PLUGIN_DESC"
echo "Version:        $PLUGIN_VERSION"
echo "Author:         $PLUGIN_AUTHOR"
echo "Group:          $PLUGIN_GROUP"
echo "Package:        $PLUGIN_GROUP.$PLUGIN_PACKAGE"
echo ""
read -p "Is this correct? (y/n): " CONFIRM

if [[ ! $CONFIRM =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

echo ""
echo "Configuring plugin..."

# Update gradle.properties
echo "Updating gradle.properties..."
sed -i "s|^group=.*|group=$PLUGIN_GROUP.$PLUGIN_PACKAGE|g" gradle.properties
sed -i "s|^version=.*|version=$PLUGIN_VERSION|g" gradle.properties
sed -i "s|^description=.*|description=$PLUGIN_DESC|g" gradle.properties
sed -i "s|^author=.*|author=$PLUGIN_AUTHOR|g" gradle.properties

# Update settings.gradle.kts
echo "Updating settings.gradle.kts..."
sed -i "s|rootProject.name = \".*\"|rootProject.name = \"$PLUGIN_NAME\"|g" settings.gradle.kts

# Update build.gradle.kts
echo "Updating build.gradle.kts..."
sed -i "s|application.mainClass = \".*\"|application.mainClass = \"$PLUGIN_GROUP.$PLUGIN_PACKAGE.Main\"|g" build.gradle.kts
sed -i "s|relocate(\"com.tcoded.folialib\", \"\${project.property(\"group\")}.lib.folialib\")|relocate(\"com.tcoded.folialib\", \"$PLUGIN_GROUP.$PLUGIN_PACKAGE.lib.folialib\")|g" build.gradle.kts

# Update plugin.yml
echo "Updating plugin.yml..."
sed -i "s|main: .*|main: $PLUGIN_GROUP.$PLUGIN_PACKAGE.Main|g" src/main/resources/plugin.yml

# Create new directory structure
echo "Refactoring directory structure..."
NEW_DIR="src/main/java/$(echo $PLUGIN_GROUP | tr '.' '/')/$PLUGIN_PACKAGE"
mkdir -p "$NEW_DIR"

# Update Main.java package declaration and move it
echo "Updating Main.java..."
sed "s|package dev.modpotato.PluginNameHere;|package $PLUGIN_GROUP.$PLUGIN_PACKAGE;|g" src/main/java/dev/modpotato/PluginNameHere/Main.java > "$NEW_DIR/Main.java"

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
