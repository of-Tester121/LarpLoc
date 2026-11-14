# LARP Location

Pick any spot on the map (or type a place / coordinates) and the app puts you there. Animated onboarding, permissions screen, favorites, recents, share button.

## Get the IPA
1. Create a GitHub repo, push all of this to `main`.
2. Go to the **Actions** tab -> **Build IPA** -> wait for it to go green.
3. Open the run -> download the `LARPLocation-ipa` artifact -> unzip -> `LARPLocation.ipa`.
4. Sideload it with Sideloadly or AltStore (they sign it with your Apple ID).

## Heads up
iOS doesn't let normal apps change the phone's real GPS. This app shows you at the fake location *inside the app* (plus a shareable text). Other apps still see your real position.
