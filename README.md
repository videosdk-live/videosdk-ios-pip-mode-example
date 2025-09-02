# Videosdk - Picture-in-Picture Mode 

## Overview

Picture-in-Picture (PiP) mode allows users to continue a video call while using other apps. This feature is especially useful for multitasking, such as taking notes, browsing the web, or accessing other tools during a call.

VideoSDK also supports multitasking camera access in PiP mode, enabling the local camera to remain active even while the app runs in the background.

## Setup Guide

- Sign up on [VideoSDK](https://app.videosdk.live/) and visit the [API Keys](https://app.videosdk.live/api-keys) section to get your API key and Secret key.
- Get familiarized with [API key and Secret key](https://docs.videosdk.live/ios/guide/video-and-audio-calling-api-sdk/signup-and-create-api).
- Get familiarized with [Token](https://docs.videosdk.live/ios/guide/video-and-audio-calling-api-sdk/server-setup).

## Prerequisites

Before running the project, ensure you have the following:
- iOS 16.0+
- Xcode 15.0+
- Swift 5.0+
- Valid [VideoSDK Account](https://app.videosdk.live/signup)

## Installation & Setup

1. Clone the repository:
   ```sh
   git clone https://github.com/videosdk-live/videosdk-ios-pip-mode-example.git
   cd videosdk-ios-pip-mode-example
   ```

2. Open the project in Xcode:
   ```sh
   open videosdk-ios-pip-mode-example.xcodeproj
   ```

3. Enable required capabilities:
   - Go to **Signing & Capabilities** in Xcode.
   - Enable **Background Modes** and check:
     - Audio, AirPlay, and Picture in Picture
     - Voice over IP

4. Inside `MeetingViewController.swift`, add the generated token in the `var token = "YOUR_TOKEN_HERE"` field.

5. Run the project on a physical iOS device (PiP is not fully supported in the iOS Simulator).

## Running the Application

1. Launch the app on your device.
2. Start a video call using the provided UI.
3. By default, the `startPiP` function will be called automatically in the `initializeMeeting` function to enable PiP mode.
4. The video window should shrink and remain visible while you switch apps.
5. PiP mode will turn off when you return to the app from the background where PiP mode was previously active.

## Resources
- [Official VideoSDK Documentation](https://docs.videosdk.live/ios/guide/video-and-audio-calling-api-sdk/concept-and-architecture)
- [PiP Documentation](https://docs.videosdk.live/ios/guide/video-and-audio-calling-api-sdk/render-media/picture-in-picture)
