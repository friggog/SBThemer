# SBThemer
Allows themers to theme the clock icon and badges through the theme's Info.plist

Add the following entries to your theme's Info.plist:
```plist
<key>SBThemerClock</key>
<dict>
  <key>redDot</key>
  <string>#EA8FA2</string>
  <key>seconds</key>
  <string>#EA8FA2</string>
  <key>blackDot</key>
  <string>#354350</string>
  <key>hours</key>
  <string>#354350</string>
  <key>minutes</key>
  <string>#354350</string>
</dict>
<key>SBThemerBadge</key>
<dict>
  <key>background</key>
  <string>#EA8FA2</string>
  <key>text</key>
  <string>#F6F6F6</string>
  <key>border</key>
  <string>#F6F6F6</string>
</dict>
```

Omitting entries will simply mean the feature is ignored, e.g. if you don't want badge borders just leave out the border key.

Currently available from my repo: http://chewitt.me/repo
