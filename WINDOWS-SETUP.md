# CarStream: Windows build and installation

This is an untested cloud-build configuration for the iPhone-only prototype, not an IPA or a CarPlay-enabled application. Requires iOS 17 or newer. No CarPlay entitlement is included.

1. Extract the entire ZIP. Create a new GitHub repository (private if desired; check Actions billing and included macOS minutes). Install GitHub Desktop from https://desktop.github.com/ if you prefer an interface instead of Git commands.
2. Clone the empty repository to your PC, then copy all the extracted files and folders into the cloned folder, including `.github/workflows/build-ios.yml`. `CarStream.xcodeproj` must be at the repository root. Commit and push the files. Do not upload Apple credentials or certificates.
3. On GitHub, open the repository > Actions > Build CarStream iOS IPA > Run workflow. Enable Actions if necessary. If the build succeeds, download the CarStream-unsigned artifact from the run summary and extract its ZIP to obtain `CarStream-unsigned.ipa`. If it fails, open the build log; no successful compilation has been verified in advance.
4. Install Sideloadly from https://sideloadly.io/ and follow its Windows prerequisites (including Apple desktop components as applicable). Connect and unlock the iPhone, trust the PC if prompted, select the device and IPA in Sideloadly, and sign with your own Apple Account locally. Follow Apple's on-device Developer Mode and trust prompts if required. Free-account signing typically expires after seven days; see the Sideloadly FAQ. Signing does not grant restricted CarPlay entitlements.
5. Follow the parked vehicle test in README.md. First test a local MP4 through AirPlay; then test YouTube if it offers a compatible video route. An audio-only connection is not sufficient. If no video destination is offered, this prototype cannot enable it.

The app is not hosted on Netlify. GitHub is used to build the app, not to serve it at runtime. YouTube requires internet. A free Apple Account may have other signing limits. Never bypass vehicle motion restrictions.
