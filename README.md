# WA2Drive

Experimental iOS project exploring encrypted WhatsApp and WhatsApp Business backups to Google Drive.

> **Status: diagnostic prototype.** This repository is not yet a working WhatsApp backup or restore tool. The current milestone is to verify what an injected library can legitimately access inside the target app process before implementing database extraction or cloud upload.

## Architecture

The intended design has two parts:

1. **Injected library** — runs inside the WhatsApp or WhatsApp Business process and performs a narrowly scoped diagnostic, then (only after access is verified) creates a consistent local backup snapshot.
2. **Companion app** — manages Google authorization, backup history, encryption settings, and restore workflow.

The planned backup pipeline is:

1. Identify the exact host app build and its effective sandbox.
2. Verify access to the relevant database, SQLite WAL/SHM files, and media.
3. Create a consistent SQLite snapshot; do not copy a live database without accounting for its WAL.
4. Enumerate and validate media/attachments.
5. Build a manifest with file sizes and cryptographic hashes.
6. Encrypt the archive locally.
7. Upload using Google Drive OAuth 2.0 Authorization Code with PKCE and resumable uploads.
8. Implement and test restore before describing an archive as WhatsApp-restorable.

## Important platform constraints

- Injecting a dylib does **not** automatically grant additional entitlements, app-group access, or access to another app's container.
- The effective sandbox and entitlements are those of the signed host process and its provisioning/signing configuration.
- WhatsApp and WhatsApp Business identifiers, app-group identifiers, and storage paths must be verified against the exact installed app build. Do not assume they are stable.
- A database not found in the host app's Documents directory is not proof that no database exists; it may be stored elsewhere or inaccessible to the injected code.
- This project does not bypass iOS sandboxing or request credentials from the user.

## Current milestone

The diagnostic probe is intended to record:

- Main bundle identifier.
- Host process home, Documents, Library, and Caches paths.
- Whether a database named `ChatStorage.sqlite` exists in a small set of conventional host-container locations.
- A diagnostic report at `Library/Caches/WA2Drive/diagnostics.txt`, if the host container permits writing there.

This is only an initial probe. It does not discover private paths, enumerate app groups, access another container, or establish that the database can be safely read.

## Build

This project uses Theos. Set up Theos and an iOS SDK, then build for the architecture supported by your target device and injection method:

```sh
make clean
make
```

The resulting dynamic library is a diagnostic artifact. Use the exact output filename produced by Theos with the injection mechanism supported by your LiveContainer setup. A successful compile does not prove that LiveContainer can load the library or that the library can access WhatsApp data.

## Security

- Never commit Google credentials, OAuth client secrets, access tokens, or refresh tokens.
- Use OAuth Authorization Code with PKCE; store tokens in Keychain in the companion app.
- Encrypt backup data locally before upload.
- Treat diagnostic logs as sensitive because they contain filesystem paths and app identifiers.
- Do not claim successful backup or restore until both have been tested on supported app versions.

## Why the original prototype was replaced

The earlier prototype hooked an unverified private view-controller class, assumed the database lived in Documents, and presented a share sheet for the raw SQLite file. Those assumptions do not establish a reliable backup. The current work starts with environment diagnostics and explicit verification instead.
