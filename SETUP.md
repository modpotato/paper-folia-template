# Setup Guide for PluginNameHere

This guide explains how to set up and build the PluginNameHere project.

## Prerequisites

- **Java 21** (JDK 21 or newer)
- **Gradle** (wrapper included, no need to install globally)
- **Git** (for cloning the repository)

## Getting Started

1. **Clone the repository:**
   ```pwsh
   git clone <your-repo-url>
   cd paper-folia-template
   ```

2. **Configure Java:**
   - Ensure `JAVA_HOME` is set to your JDK 21 installation.
   - On Windows, you can set it in PowerShell:
     ```pwsh
     $env:JAVA_HOME = 'C:\Path\To\Your\JDK21'
     ```

3. **Build the plugin:**
   - Use the Gradle wrapper to build:
     ```pwsh
     ./gradlew build
     ```
   - The output JAR will be in `build/libs/`.

4. **Run a test server (optional):**
   - To run a local Paper server for testing:
     ```pwsh
     ./gradlew runServer
     ```
   - The server will use the version specified in `gradle.properties`.

## Configuration

- Main plugin code is in `src/main/java/top/modpotato/PluginNameHere/Main.java`.
- Plugin metadata is in `src/main/resources/plugin.yml`.
- Dependency versions and plugin info are managed in `gradle.properties`.

## Customization

- Change the plugin name, author, and description in `gradle.properties` and `settings.gradle.kts`.
- Update dependencies in `build.gradle.kts` as needed.

---

For any issues, refer to the [README.md](README.md) or open an issue in the repository.
