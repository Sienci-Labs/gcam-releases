# gcam-releases

## gCAM checks

Since 24 November 2026, this repository runs quality and browser tests for the
latest commit on private gCAM's `main` branch. A scheduled check looks for a new
commit every 15 minutes and queues tests if it finds one. Test results appear in
this repository's Actions tab; they are not pull-request status checks. If several
commits arrive between checks, only the latest is tested. Raw test output is
discarded; failed browser checks report spec names and counts. Render deploys
the web app separately from `main`.

The installer workflow below is retained for reference and is not part of these
checks.

This repository contains the manual workflow for building gCAM. The source,
release notes, installers and checksums stay in the private gCAM repository.

## Set up the release environment

In this repository, open **Settings → Environments → gcam-private-release**.
Restrict deployments to `main` and protect `main` against unreviewed workflow
changes. Keep Actions step and runner debug logging disabled. Give the
environment these secrets:

| Secret | Access |
| --- | --- |
| `GCAM_RELEASE_TOKEN` | Fine-grained token for `Sienci-Labs/gCAM` only, with **Contents: read and write** for checkout and release uploads. |
| `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD` | The existing Android release signing identity. |

Use Sienci Labs as the token resource owner and get organization approval if
required. A token with Contents write can also change the repository, so use
short expirations and keep it scoped to gCAM. Supply the existing optional
Windows signing secrets if needed. macOS releases require the Developer ID signing bundle and Apple notarization secrets. Android is the supported tablet target.

## Build a draft

1. Push a stable tag on private `main` and create a draft release for it in the
   private repository.
2. In this repository, run **Build private gCAM release** from `main` and enter
   that tag. The workflow verifies the private commit and runs quality checks
   and browser tests before building the installers.
3. Review the installers and `SHA256SUMS.txt` in the private draft and publish
   there when ready.

The workflow uploads directly to the private draft and creates no public
Actions artifacts or caches. Public logs show job status and limited checkout
metadata. Build and test output is discarded. Reproduce failures in a private
workspace to inspect their details.
