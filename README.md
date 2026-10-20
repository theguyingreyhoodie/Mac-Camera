# Mac Camera

A Photo Booth–style camera app for macOS, built with SwiftUI, AVFoundation, Metal and Core Image.

## Features

- Live, mirrored camera preview rendered with Metal
- 10 filters (Normal, Mono, Noir, Sepia, Chrome, Fade, Instant, Comic, Pixel, Thermal) with a live thumbnail strip
- Countdown timer (3s, 5s, 10s) and an optional screen flash
- Camera picker for Macs with more than one camera
- Option to mirror saved photos to match the preview
- Photos are saved to `~/Pictures/Photobooth`

## Requirements

- macOS 26.6 or later
- Xcode 26

## Build and run

1. Open `Camera.xcodeproj` in Xcode.
2. Select the `Camera` scheme and press **⌘R**.
3. Allow camera access when macOS asks.

Run the tests with **⌘U**.

## Project layout

```
Camera/
  App/         app entry point
  Camera/      capture session, device discovery, permissions
  Rendering/   Metal preview
  Filters/     filter definitions and thumbnails
  State/       view model, settings, countdown
  Views/       SwiftUI views
  Utilities/   file storage, photo processing, shutter sound
CameraTests/   unit tests
```
