$env:JAVA_HOME = "C:\Users\Public\Documents\WebVault\tools\jdk-17"
$env:ANDROID_HOME = "C:\Users\Public\Documents\WebVault\tools\android-sdk"
$env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
$env:ANDROID_AVD_HOME = "C:\Users\Public\Documents\WebVault\tools\android-avd"
$env:Path = "C:\Users\rdzio\Tools\flutter\bin;$env:JAVA_HOME\bin;$env:ANDROID_HOME\emulator;$env:ANDROID_HOME\platform-tools;$env:ANDROID_HOME\cmdline-tools\latest\bin;$env:Path"

Write-Host "Android/Flutter environment configured for this PowerShell session."
Write-Host "Flutter SDK: C:\Users\rdzio\Tools\flutter"
Write-Host "Android SDK: $env:ANDROID_HOME"
Write-Host "AVD home: $env:ANDROID_AVD_HOME"
Write-Host "JDK: $env:JAVA_HOME"
