#!/bin/bash
echo "Setting up ADB Reverse..."
adb reverse tcp:3000 tcp:3000
echo "Starting Flutter App..."
flutter run
