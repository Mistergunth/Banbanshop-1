@echo off
echo Installing Flutter dependencies...
flutter pub get

echo Launching Android emulator...
call flutter emulators --launch flutter_emulator

timeout /t 10 /nobreak >nul

echo Building and running the app...
flutter run -d emulator-5554
