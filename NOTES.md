# NOTES

- Cloning the pmOS CI recipe to a new app needs ALL FOUR: ci.yml + ExportOptions.plist + an AppIcon in the asset catalog (upload hard-fails without 120x120/CFBundleIconName) + ASC_KEY_P8 secret as BASE64 (the workflow base64-decodes it; raw PEM gives JWT keyPathInvalid).
- ASC app records: user-created dropdown picks the wrong bundle twice now (pmOS, ConyOS). Fix via API: POST /v1/bundleIds then PATCH /v1/apps/<id> attributes.bundleId works pre-release. Issuer 9c44682c-3cc3-4791-bd10-a2d8935788db, key KB93R49B9J.
