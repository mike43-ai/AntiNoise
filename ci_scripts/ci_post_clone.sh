#!/bin/sh
set -e

echo "==> Installing xcodegen via Homebrew"
brew install xcodegen

echo "==> Generating Xcode project from project.yml"
cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate

echo "==> ci_post_clone done"
