Hinner jag? Sthlm
=================
This is the complete source code of the iOS app "Hinner jag? Sthlm".

When you create pull requests, make sure to base them on [the "develop" branch](https://github.com/willeeklund/Hinner-jag/tree/develop). This is required since I use Git Flow and changes not yet released are in develop.

## Different XCode targets for the app
* Hinner jag - The main iOS app.
* Hinner jag widget - Today Extension where departures from closest station are shown without user needing to unlock their phone.
* HinnerJagKit - framework with all common logic between the different targets. All model parts of the app is here.
* HinnerJagWatchOS2 - WatchKit app
* HinnerJagWatchOS2 Extension - Watchkit app extension with code for the WatchKit app.
* HinnerJagWatchKit - framework for WatchKit app. Extending HinnerJagKit with minor changes needed for WatchOS.
