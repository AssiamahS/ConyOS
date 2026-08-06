# NOTES

- Cloning the pmOS CI recipe to a new app needs ALL FOUR: ci.yml + ExportOptions.plist + an AppIcon in the asset catalog (upload hard-fails without 120x120/CFBundleIconName) + ASC_KEY_P8 secret as BASE64 (the workflow base64-decodes it; raw PEM gives JWT keyPathInvalid).
- ASC app records: user-created dropdown picks the wrong bundle twice now (pmOS, ConyOS). Fix via API: POST /v1/bundleIds then PATCH /v1/apps/<id> attributes.bundleId works pre-release. Issuer 9c44682c-3cc3-4791-bd10-a2d8935788db, key KB93R49B9J.
- Global ~/.git-hooks/pre-push auto-bumps the version by amending HEAD, but the push still sends the pre-amend ref — local ends up one commit ahead every push, forever. When the version was already bumped by hand in the commit, push with --no-verify.
- Cert cap: every cloud-signed CI run mints a throwaway "Created via API" DEVELOPMENT cert; the second run of the day died with "Choose a certificate to revoke". Fix: DELETE /v1/certificates/<id> for the Created-via-API one (204), keep "Sylvester Assiamah" IOS_DEVELOPMENT, then gh run rerun --failed.
- Cloud sync: reads go through the cony-relay worker (wrangler config in Cony/relay); the read key is the CONY_APP_KEY repo secret, sed'd into Secrets.swift by the testflight job. Rotate = new `wrangler secret put APP_KEY` + update repo secret + new build.
