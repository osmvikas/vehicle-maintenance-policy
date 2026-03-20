#!/bin/bash

echo "========================================================"
echo "  Vehicle Maintenance - Play Store Build Script"
echo "========================================================"

# Set Java
export JAVA_HOME=$(readlink -f /usr/bin/java | sed 's|/bin/java||')
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=$HOME/android-sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools

cd /workspaces/Vehicle-Maintenance-Management/VehicleMaintenanceV2

echo ""
echo "[1/3] Generating keystore..."
echo ""

# Generate keystore (non-interactive with preset values)
keytool -genkey -v \
  -keystore vehicle-release.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias vehicle \
  -dname "CN=Vehicle Maintenance, OU=App, O=VehicleMaintenance, L=Agra, S=Uttar Pradesh, C=IN" \
  -storepass vehicleapp123 \
  -keypass vehicleapp123

echo ""
echo "[2/3] Adding signing config to build.gradle..."

# Backup original
cp app/build.gradle app/build.gradle.bak

# Write new build.gradle with signing config
cat > app/build.gradle << 'GRADLE'
plugins {
    id 'com.android.application'
    id 'com.google.gms.google-services'
}

android {
    namespace 'com.vehiclemaintenance'
    compileSdk 34

    defaultConfig {
        applicationId "com.vehiclemaintenance"
        minSdk 24
        targetSdk 34
        versionCode 1
        versionName "1.0"
        multiDexEnabled true
    }

    signingConfigs {
        release {
            storeFile file('vehicle-release.jks')
            storePassword 'vehicleapp123'
            keyAlias 'vehicle'
            keyPassword 'vehicleapp123'
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            signingConfig signingConfigs.release
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
        debug {
            signingConfig signingConfigs.debug
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }

    packaging {
        resources {
            excludes += ['META-INF/DEPENDENCIES', 'META-INF/LICENSE', 'META-INF/LICENSE.txt', 'META-INF/NOTICE', 'META-INF/NOTICE.txt']
        }
    }
}

dependencies {
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.11.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    implementation 'androidx.recyclerview:recyclerview:1.3.2'
    implementation 'androidx.cardview:cardview:1.0.0'
    implementation 'androidx.multidex:multidex:2.0.1'
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-auth'
    implementation 'com.google.firebase:firebase-analytics'
    implementation 'com.google.android.gms:play-services-auth:20.7.0'
    implementation 'com.itextpdf:itext7-core:7.2.5'
}
GRADLE

echo ""
echo "[3/3] Building release APK..."
echo ""

./gradlew assembleRelease --no-daemon

echo ""
echo "========================================================"
echo "  DONE!"
echo "========================================================"
echo ""

APK=$(find . -name "app-release.apk" | head -1)
if [ -n "$APK" ]; then
    echo "  Release APK: $APK"
    echo ""
    echo "  Keystore file : vehicle-release.jks"
    echo "  Store password: vehicleapp123"
    echo "  Key alias     : vehicle"
    echo "  Key password  : vehicleapp123"
    echo ""
    echo "  IMPORTANT: Download and save vehicle-release.jks"
    echo "  You need it for every future app update!"
else
    echo "  Build may have failed. Check errors above."
fi
echo "========================================================"
