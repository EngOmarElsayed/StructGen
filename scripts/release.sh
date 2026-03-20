#!/bin/bash
set -euo pipefail

# ─────────────────────────────────────────────
# StructGen Release Script
# Creates a .dmg from a notarized .app and
# publishes a GitHub release with it.
# ─────────────────────────────────────────────

REPO="EngOmarElsayed/StructGen"
APP_NAME="StructGen"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
OUTPUT_DIR="$PROJECT_DIR/release"

# Colors
BOLD="\033[1m"
CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
RESET="\033[0m"

info()    { echo -e "${CYAN}ℹ${RESET}  $1"; }
success() { echo -e "${GREEN}✔${RESET}  $1"; }
warn()    { echo -e "${YELLOW}⚠${RESET}  $1"; }
error()   { echo -e "${RED}✖${RESET}  $1"; exit 1; }
prompt()  { echo -en "${BOLD}$1${RESET}"; }

# ─────────────────────────────────────────────
# Preflight checks
# ─────────────────────────────────────────────
command -v gh >/dev/null 2>&1      || error "GitHub CLI (gh) is not installed. Run: brew install gh"
command -v hdiutil >/dev/null 2>&1 || error "hdiutil not found. Are you on macOS?"
gh auth status >/dev/null 2>&1     || error "Not logged in to GitHub. Run: gh auth login"

echo ""
echo -e "${BOLD}╔════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║       StructGen Release Script         ║${RESET}"
echo -e "${BOLD}╚════════════════════════════════════════╝${RESET}"
echo ""

# ─────────────────────────────────────────────
# Step 1: Ask for the notarized .app path
# ─────────────────────────────────────────────
prompt "📦 Path to notarized .app: "
read -r APP_PATH

# Expand ~ if used
APP_PATH="${APP_PATH/#\~/$HOME}"
# Remove trailing slash
APP_PATH="${APP_PATH%/}"

# Validate
[[ -d "$APP_PATH" ]]                       || error "Path does not exist: $APP_PATH"
[[ "$APP_PATH" == *.app ]]                 || error "Path must point to a .app bundle: $APP_PATH"
[[ -f "$APP_PATH/Contents/Info.plist" ]]   || error "Not a valid .app bundle (missing Info.plist): $APP_PATH"

success "Found app: $APP_PATH"

# ─────────────────────────────────────────────
# Step 2: Ask for the release version
# ─────────────────────────────────────────────
echo ""

# Fetch latest release version from GitHub
LATEST_VERSION=$(gh release view --repo "$REPO" --json tagName --jq '.tagName' 2>/dev/null || echo "none")

if [[ "$LATEST_VERSION" == "none" ]]; then
    info "No previous releases found on GitHub."
    SUGGESTED_VERSION="1.0.0"
else
    info "Latest release: ${BOLD}${LATEST_VERSION}${RESET}"
    # Suggest a patch bump
    VERSION_NUM="${LATEST_VERSION#v}"
    IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION_NUM"
    PATCH=$((PATCH + 1))
    SUGGESTED_VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

prompt "🏷  Release version [${SUGGESTED_VERSION}]: "
read -r VERSION_INPUT
VERSION="${VERSION_INPUT:-$SUGGESTED_VERSION}"

# Ensure the version starts with "v"
[[ "$VERSION" == v* ]] || VERSION="v$VERSION"

info "Release version: ${BOLD}${VERSION}${RESET}"

# Check if this tag already exists
if gh release view "$VERSION" --repo "$REPO" >/dev/null 2>&1; then
    error "Release $VERSION already exists on GitHub. Choose a different version."
fi

# ─────────────────────────────────────────────
# Step 3: Ask for release notes
# ─────────────────────────────────────────────
echo ""
info "Enter release notes below (press ${BOLD}Ctrl+D${RESET} on an empty line when done):"
echo -e "${YELLOW}───────────────────────────────────${RESET}"
RELEASE_NOTES=$(cat)
echo -e "${YELLOW}───────────────────────────────────${RESET}"

[[ -n "$RELEASE_NOTES" ]] || error "Release notes cannot be empty."
success "Release notes captured."

# ─────────────────────────────────────────────
# Step 4: Create the .dmg
# ─────────────────────────────────────────────
echo ""
info "Creating .dmg..."

mkdir -p "$OUTPUT_DIR"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
DMG_PATH="$OUTPUT_DIR/$DMG_NAME"

# Clean up previous dmg if it exists
[[ -f "$DMG_PATH" ]] && rm -f "$DMG_PATH"

# Create a temporary directory for the DMG contents
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Copy the .app into the temp dir
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create a symlink to /Applications for drag-install
ln -s /Applications "$TEMP_DIR/Applications"

# Create the DMG
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH" \
    >/dev/null 2>&1

[[ -f "$DMG_PATH" ]] || error "Failed to create .dmg"

DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1 | xargs)
success "Created: ${BOLD}${DMG_PATH}${RESET} (${DMG_SIZE})"

# ─────────────────────────────────────────────
# Step 5: Create GitHub release
# ─────────────────────────────────────────────
echo ""
info "Creating GitHub release ${BOLD}${VERSION}${RESET}..."

gh release create "$VERSION" \
    "$DMG_PATH" \
    --repo "$REPO" \
    --title "${APP_NAME} ${VERSION}" \
    --notes "$RELEASE_NOTES"

RELEASE_URL=$(gh release view "$VERSION" --repo "$REPO" --json url --jq '.url')

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}║         Release published!             ║${RESET}"
echo -e "${GREEN}╚════════════════════════════════════════╝${RESET}"
echo ""
success "Version:  ${BOLD}${VERSION}${RESET}"
success "DMG:      ${BOLD}${DMG_PATH}${RESET}"
success "Release:  ${BOLD}${RELEASE_URL}${RESET}"
echo ""
