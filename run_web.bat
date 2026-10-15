@echo off
echo ====================================================================
echo Menjalankan ServisKu pada Chrome dengan Local Storage Persisten...
echo Port tetap: http://localhost:5000
echo Direktori profil: .chrome_data
echo ====================================================================
flutter run -d chrome --web-port=5000 --web-browser-flag="--user-data-dir=%~dp0.chrome_data"
