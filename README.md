# CarStream v0.1 — iPhone compatibility prototype

This is a native SwiftUI iOS source project, not a signed IPA or a native CarPlay app. It needs Xcode and an iPhone running iOS 17 or later. Use a recent Xcode version that supports your phone's iOS release.

## Run on your iPhone

For Windows, see WINDOWS-SETUP.md for the alternative cloud build and local signing workflow.
1. Unzip the package on your Mac and open `CarStream.xcodeproj`.
2. In Xcode > Settings > Accounts, add your Apple Account if needed.
3. Select the CarStream project and target > Signing & Capabilities. Enable automatic signing and select your team (Personal Team is fine for basic iPhone testing). If the bundle ID is unavailable, change it to something unique.
4. Connect your iPhone to the Mac, unlock and trust it. Choose it as the Xcode run destination. Enable Developer Mode if prompted by iOS (Settings > Privacy & Security > Developer Mode).
5. Click Run. Xcode builds, signs and installs the app. The project has no third-party packages or external backend.

## Test while parked
1. Open CarStream and test YouTube search and ordinary web playback with internet on the iPhone. YouTube may restrict some web playback or sign-in functionality.
2. In the Offline tab, import a short MP4 video you own using Files. Play it locally, then turn internet off and verify it still plays on the phone.
3. With the vehicle safely parked, connect normal CarPlay. Use the Offline tab's AirPlay route picker to check for a video-capable destination. If offered, select it and test your own video. A CarPlay audio connection is not evidence of video capability.
4. If video works, try YouTube's own AirPlay control (if exposed by the web player). The route picker alone does not guarantee that a WKWebView video can be routed externally.
5. If no supported video destination is offered, the prototype cannot send video to that receiver. Do not attempt to bypass vehicle or OS safety restrictions.

## Included
- Mobile YouTube website in WKWebView, search and links, reload/back/forward.
- Locally saved page bookmarks (not downloaded YouTube videos).
- Local video import, persistence, playback, deletion and AirPlay route picker.
- Compatibility test guidance.

## Not included
- CarPlay dashboard icon, CarPlay templates or video entitlement. Native CarPlay video integration requires an Apple-granted entitlement, compatible SDK and supported receiver. This prototype intentionally does not claim or fake authorization.
- YouTube downloads, extraction, background playback modifications, or a server.
- Signed installer. Use Xcode device deployment or the cloud build and local signing workflow in WINDOWS-SETUP.md. Personal Team provisioning may expire and require reinstalling/re-signing.

## Validation
Swift source was syntax-parsed and the Xcode project property list was linted in a non-Apple build environment. iOS SDK compilation, code signing, runtime behavior, YouTube playback and vehicle compatibility have NOT been verified. This is an experimental first draft.

Apple CarPlay developer documentation: https://developer.apple.com/carplay/
Apple preparation instructions: https://developer.apple.com/documentation/carplay/preparing-your-ios-app-for-carplay-development
