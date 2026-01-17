# Fixing Java 17 Requirement for Gradle

## Problem
Gradle daemon is crashing because it's using Java 21/22, but Flutter Android builds require Java 17.

## Solution Options

### Option 1: Download Java 17 (Recommended - Fastest)

1. **Download Java 17:**
   - Go to: https://adoptium.net/temurin/releases/?version=17
   - Download Windows x64 JDK (e.g., `jdk-17.0.13_windows-x64_bin.zip`)
   - Extract to: `C:\Program Files\Java\jdk-17`

2. **Update gradle.properties:**
   - Open `synapse/android/gradle.properties`
   - Uncomment and update this line:
     ```
     org.gradle.java.home=C:\\Program Files\\Java\\jdk-17
     ```

3. **Stop Gradle daemons:**
   ```powershell
   cd synapse/android
   .\gradlew.bat --stop
   ```

4. **Try building:**
   ```powershell
   flutter clean
   flutter run
   ```

### Option 2: Use Auto-Download (Slower, but automatic)

Gradle can auto-download Java 17, but it requires:
1. Internet connection
2. First build will be slower (downloads Java 17)

**Steps:**
1. Make sure `gradle.properties` has:
   ```
   org.gradle.java.installations.auto-detect=true
   org.gradle.java.installations.auto-download=true
   ```

2. Stop all daemons:
   ```powershell
   cd synapse/android
   .\gradlew.bat --stop
   ```

3. Run build (Gradle will download Java 17 on first run):
   ```powershell
   flutter clean
   flutter run
   ```

### Option 3: Use Android Studio's Java 17 (If Available)

If Android Studio has Java 17 bundled:
1. Find Android Studio installation (usually: `C:\Program Files\Android\Android Studio\jbr`)
2. Check if there's a `jbr-17` folder
3. If found, set in `gradle.properties`:
   ```
   org.gradle.java.home=C:\\Program Files\\Android\\Android Studio\\jbr-17
   ```

## Quick Fix Script

Run the PowerShell script:
```powershell
cd synapse/android
.\configure-java17.ps1
```

This will:
- Stop Gradle daemons
- Search for Java 17
- Update `gradle.properties` if found

## Verify Java Version

After configuration, verify:
```powershell
cd synapse/android
.\gradlew.bat --version
```

Should show: `Daemon JVM: ... (Java 17)`
