#!/bin/bash
set -e
echo "Running build and tests..."
xcodebuild -scheme PokedexiOS -destination 'platform=iOS Simulator,name=iPhone 15'
