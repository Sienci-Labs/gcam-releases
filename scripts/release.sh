#!/usr/bin/env bash
set -euo pipefail

quiet() {
    local log
    log="$(mktemp)"
    if "$@" >"$log" 2>&1; then
        rm -f -- "$log"
    else
        rm -f -- "$log"
        echo "Private release step failed: $1. Reproduce it in a private workspace." >&2
        return 1
    fi
}

renderer() {
    quiet corepack enable
    export CYPRESS_INSTALL_BINARY=0
    (
        cd react
        quiet yarn install --frozen-lockfile
        quiet yarn build --base ./
    )
}

private_draft() {
    release_repo=Sienci-Labs/gCAM
    if [[ "$(gh repo view "$release_repo" --json visibility --jq .visibility 2>/dev/null)" != PRIVATE ||
          "$(gh release view "$RELEASE_TAG" -R "$release_repo" --json isDraft --jq .isDraft 2>/dev/null)" != true ]]; then
        echo 'A draft in the private gCAM repository is required.' >&2
        return 1
    fi
}

case "$1" in
    quality)
        quiet corepack enable
        export CYPRESS_INSTALL_BINARY=0
        (
            cd react
            quiet yarn install --frozen-lockfile
            quiet yarn test --runInBand
            quiet yarn check-types
            quiet yarn lint
            quiet yarn format:check
            quiet yarn build
        )
        quiet node --test packaging/desktop/*.test.cjs packaging/scripts/*.test.mjs packaging/plugins/gcam-files/*.test.cjs
        (cd packaging && quiet node ../react/node_modules/@biomejs/biome/bin/biome check .)
        ;;
    browser)
        quiet corepack enable
        (
            cd react
            export CYPRESS_CACHE_FOLDER="$RUNNER_TEMP/gcam-cypress"
            CYPRESS_INSTALL_BINARY=0 quiet yarn install --frozen-lockfile
            quiet yarn cypress install
            specs="$(node --input-type=module -e 'import { readdirSync } from "node:fs"; console.log(readdirSync("cypress/e2e",{recursive:true}).filter(n=>n.endsWith(".cy.js")).sort().filter((_,i)=>i%4===Number(process.env.TEST_SHARD)).map(n=>"cypress/e2e/"+n).join(","))')"
            quiet xvfb-run -a yarn test:e2e "$specs"
        )
        ;;
    desktop)
        quiet node packaging/scripts/release-version.mjs
        renderer
        quiet node packaging/scripts/stage.mjs desktop
        cd packaging/desktop
        quiet npm ci
        quiet npm test
        if [[ "$2" == linux ]]; then
            quiet xvfb-run -a node_modules/.bin/electron --no-sandbox smoke.cjs
        else
            quiet npm run smoke
        fi
        ;;
    package-desktop)
        if [[ -z "$CSC_LINK" ]]; then
            unset CSC_LINK CSC_KEY_PASSWORD
            export CSC_IDENTITY_AUTO_DISCOVERY=false
        fi
        cd packaging/desktop
        quiet npm run package -- "--$2" "--$3"
        if [[ "$2" == mac ]]; then
            quiet xcrun lipo dist/mac-arm64/gCAM.app/Contents/MacOS/gCAM -verify_arch arm64
        fi
        ;;
    mobile)
        quiet node packaging/scripts/release-version.mjs
        renderer
        quiet node packaging/scripts/stage.mjs mobile
        (cd packaging/mobile && quiet npm ci)
        quiet node packaging/scripts/mobile-platform.mjs "$2"
        cd packaging/mobile
        quiet npx cordova plugin add ../plugins/gcam-files ../plugins/gcam-updates --nosave
        quiet npx cordova prepare "$2"
        ;;
    android)
        trap 'quiet node packaging/scripts/android-signing.mjs --clean' EXIT
        quiet node packaging/scripts/android-signing.mjs
        (
            cd packaging/mobile
            quiet npx cordova build android --release --buildConfig=build.json -- --packageType=apk
            quiet npx cordova build android --release --buildConfig=build.json -- --packageType=bundle
            version="$RELEASE_TAG"
            mkdir -p dist
            cp platforms/android/app/build/outputs/apk/release/app-release.apk "dist/gCAM-${version#v}-android.apk"
            cp platforms/android/app/build/outputs/bundle/release/app-release.aab "dist/gCAM-${version#v}-android.aab"
        )
        ;;
    simulator)
        cd packaging/mobile
        quiet npx cordova build ios --debug --emulator -- \
            --buildFlag=CODE_SIGNING_ALLOWED=NO --buildFlag="ARCHS=arm64 x86_64"
        quiet xcrun lipo platforms/ios/build/Debug-iphonesimulator/gCAM.app/gCAM -verify_arch arm64 x86_64
        quiet ditto -c -k --sequesterRsrc --keepParent platforms/ios/build/Debug-iphonesimulator/gCAM.app gCAM-ipad-simulator.zip
        ;;
    upload)
        shift
        private_draft
        shopt -s nullglob
        files=()
        for pattern in "$@"; do
            while IFS= read -r file; do
                [[ -f "$file" ]] && files+=("$file")
            done < <(compgen -G "$pattern" || true)
        done
        [[ ${#files[@]} -gt 0 ]] || { echo 'No matching private release files.' >&2; exit 1; }
        quiet gh release upload "$RELEASE_TAG" -R "$release_repo" "${files[@]}" --clobber
        ;;
    verify)
        private_draft
        dir="$(mktemp -d)"
        cd "$dir"
        quiet gh release download "$RELEASE_TAG" -R "$release_repo" --pattern '*' --dir .
        version="${RELEASE_TAG#v}"
        for required in "gCAM-$version-win-x64.exe" "gCAM-$version-linux-x86_64.AppImage" \
            "gCAM-$version-mac-arm64.dmg" "gCAM-$version-mac-arm64.zip" \
            "gCAM-$version-android.apk" "gCAM-$version-android.aab" \
            gCAM-ipad-simulator.zip latest.yml latest-linux.yml latest-mac.yml; do
            [[ -s "$required" ]] || { echo 'A required private release asset is missing.' >&2; exit 1; }
        done
        find . -maxdepth 1 -type f ! -name SHA256SUMS.txt -printf '%f\0' |
            LC_ALL=C sort -z | xargs -0 sha256sum > SHA256SUMS.txt
        private_draft
        quiet gh release upload "$RELEASE_TAG" -R "$release_repo" SHA256SUMS.txt --clobber
        ;;
    *)
        exit 2
        ;;
esac
