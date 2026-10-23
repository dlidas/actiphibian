# Actiphibian

Actiphibian is an amphibian themed productivity app built with Flutter. Plan tasks and habits, focus with a timer, earn experience and coins, and grow an amphibian collection.

## Demo video link

Watch a demo of the prototype [here](https://drive.google.com/file/d/1izKtIO3njXk4LXup9CjTv_tGe0aKs86_/view?usp=sharing).

## Features

**Home** gives quick access to tasks and focus sessions.

**Tasks** lets you create and manage tasks and recurring habits.

**Focus** provides a configurable timer, distraction tracking, and rewards for completed sessions.

**Calendar** displays scheduled tasks and habits.

**Collection** lets you discover and view amphibians.

**Profile and statistics** show progress, including experience, coin balance, tasks, and collected amphibians.

**Pond Mates** currently displays sample entries and is not connected to an online social service.

## Data

The app uses a local SQLite database to store user, task, habit, focus session, and amphibian collection data on the device.

## Requirements

Install the Flutter SDK with Dart 3.12.2 or newer. To run the app on a device or emulator, install the development tools for that platform.

## Run the app

From the project directory, fetch dependencies and start the app:

```text
flutter pub get
flutter run
```

## Check the code

Run the Dart and Flutter analyzer from the project directory:

```text
flutter analyze
```

## Project folders

Application code lives in `lib/`. Images and other bundled data live in `assets/images/` and `assets/data/`.

## Attribution

The app icon illustration was created by Magnific and provided through [Flaticon](https://www.flaticon.com).
