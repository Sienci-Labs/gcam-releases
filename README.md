# gcam-releases

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
Windows and Mac signing secrets if those builds should be signed. The iPad
build is a simulator archive. TestFlight submission stays in the private
workflow.

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
