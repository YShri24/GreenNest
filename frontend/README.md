# GreenNest Flutter Frontend Setup Guide

This guide walks you through setting up the Flutter environment on your Windows machine to run the **GreenNest Mobile Application**.

---

## Step 1: Install the Flutter SDK

1.  **Download Flutter**:
    *   Go to the official Flutter website: [flutter.dev](https://docs.flutter.dev/get-started/install/windows)
    *   Download the latest stable release zip file (e.g. `flutter_windows_x.x.x-stable.zip`).
2.  **Extract the SDK**:
    *   Extract the zip file to an installation path that does not contain spaces (e.g., `C:\src\flutter`).
    *   *Do NOT install Flutter in a directory like `C:\Program Files` which requires administrator privileges.*

---

## Step 2: Configure Environment Variables

To run Flutter commands in your PowerShell or Command Prompt, you need to add it to your system PATH:

1.  In the Windows Search bar, type **env** and select **Edit the system environment variables**.
2.  Click the **Environment Variables...** button at the bottom.
3.  Under **User variables**, find the variable named `Path` and double-click it.
4.  Click **New** and add the absolute path to the `bin` directory of your extracted Flutter folder.
    *   Example: `C:\src\flutter\bin`
5.  Click **OK** on all windows to save the changes.
6.  Open a new PowerShell terminal and run:
    ```powershell
    flutter --version
    ```
    *If successful, it will display the installed Flutter and Dart versions.*

---

## Step 3: Set Up Android Studio & Emulator

1.  **Download & Install Android Studio**:
    *   Go to [developer.android.com/studio](https://developer.android.com/studio) and download the Windows installer.
    *   Run the installer and complete the setup wizard.
2.  **Install Android SDK Command-line Tools**:
    *   Open Android Studio.
    *   Go to **Tools** > **SDK Manager** (or **More Actions** > **SDK Manager** on the welcome screen).
    *   Select the **SDK Tools** tab.
    *   Check **Android SDK Command-line Tools (latest)**.
    *   Click **Apply** and follow the prompts to install.
3.  **Accept Licenses**:
    *   Open a new PowerShell window and run:
        ```powershell
        flutter doctor --android-licenses
        ```
    *   Press `y` to accept every license agreement.
4.  **Create an Emulator**:
    *   In Android Studio, go to **Tools** > **Device Manager**.
    *   Click **Create Device** and select a phone template (e.g., Pixel 7).
    *   Download a system image (e.g., Android API 33 or 34).
    *   Click **Finish** to create the Virtual Device. You can launch it by clicking the Play icon.

---

## Step 4: Run the GreenNest Application

Once the environment setup is complete, you can start the application:

1.  **Start the Backend**:
    *   Open a terminal and navigate to the backend folder:
        ```powershell
        cd c:\Umang\backend
        python run.py
        ```
    *   *This will install Python dependencies, seed the SQLite database, and run the server at `http://127.0.0.1:8000`.*

2.  **Run the Flutter Application**:
    *   Open another terminal, navigate to the frontend folder:
        ```powershell
        cd c:\Umang\frontend
        ```
    *   Fetch Flutter package dependencies:
        ```powershell
        flutter pub get
        ```
    *   Verify your environment status (optional):
        ```powershell
        flutter doctor
        ```
    *   Launch the app on your running Android Emulator or connected device:
        ```powershell
        flutter run
        ```
