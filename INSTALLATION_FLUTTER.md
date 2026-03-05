# Guide Separe - Installation et Configuration de Flutter

## 1. Objectif
Ce document couvre uniquement:
- l'installation de Flutter
- la configuration des outils necessaires
- la verification de l'environnement
- la resolution des problemes les plus frequents

Ce guide est pense d'abord pour Windows, avec des notes macOS/Linux quand utile.

## 2. Prerequis

### 2.1 Materiel minimum
- OS: Windows 10/11 64-bit, macOS 12+, ou Linux Ubuntu 20.04+
- RAM: 8 Go minimum (16 Go recommande)
- Espace disque: 10 Go minimum

### 2.2 Logiciels requis
- Git
- Flutter SDK (inclut Dart)
- JDK 17 (pour Android)
- Android SDK Command-line Tools (si cible Android)
- Google Chrome (si cible Web)
- Visual Studio Community + Desktop development with C++ (si cible Windows Desktop)

## 3. Installation Flutter

### 3.1 Telecharger Flutter SDK
1. Aller sur: https://flutter.dev/docs/get-started/install
2. Choisir votre OS
3. Telecharger l'archive stable
4. Extraire dans un chemin simple, par exemple:
   - `C:\dev\flutter` (Windows)

Eviter les chemins avec espaces quand c'est possible.

### 3.2 Ajouter Flutter au PATH

#### Windows (PowerShell)
```powershell
setx PATH "$env:PATH;C:\dev\flutter\bin"
```
Fermez et reouvrez le terminal apres la commande.

#### macOS/Linux (bash/zsh)
```bash
export PATH="$PATH:/chemin/vers/flutter/bin"
```
Ajoutez cette ligne dans `~/.bashrc` ou `~/.zshrc`.

### 3.3 Verifier l'installation
```bash
flutter --version
flutter doctor
```

## 4. Configuration Android (sans IDE Android)

### 4.1 Installer JDK 17
Sous Windows, exemple via winget:
```powershell
winget install --id EclipseAdoptium.Temurin.17.JDK -e --accept-package-agreements --accept-source-agreements
```
Verifier:
```powershell
java -version
```

### 4.2 Installer Android SDK Command-line Tools
1. Telecharger: https://developer.android.com/studio#command-tools
2. Decompresser dans:
   - `C:\Android\Sdk\cmdline-tools\latest`

Structure attendue:
- `C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat`

### 4.3 Variables d'environnement Android (Windows)
```powershell
setx ANDROID_SDK_ROOT "C:\Android\Sdk"
setx ANDROID_HOME "C:\Android\Sdk"
setx PATH "$env:PATH;C:\Android\Sdk\platform-tools;C:\Android\Sdk\cmdline-tools\latest\bin"
```
Fermez et reouvrez le terminal.

### 4.4 Installer les composants Android requis
```powershell
C:\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat --sdk_root=C:\Android\Sdk "platform-tools" "platforms;android-36" "build-tools;36.0.0"
```

### 4.5 Pointer Flutter vers le SDK Android
```powershell
flutter config --android-sdk "C:\Android\Sdk"
```

### 4.6 Accepter les licences Android
```powershell
flutter doctor --android-licenses
```

## 5. Configuration Web (Chrome)

### 5.1 Installer Chrome
Sous Windows:
```powershell
winget install --id Google.Chrome -e --accept-package-agreements --accept-source-agreements
```

### 5.2 Definir CHROME_EXECUTABLE (si necessaire)
```powershell
setx CHROME_EXECUTABLE "C:\Program Files\Google\Chrome\Application\chrome.exe"
```

## 6. Configuration Windows Desktop (si cible Windows)

Installer Visual Studio Community et cocher la charge de travail:
- `Desktop development with C++`

Verifier:
```bash
flutter doctor
```

## 7. Verification finale
Lancer:
```bash
flutter doctor
```

Etat attendu (exemple):
- Flutter: OK
- Android toolchain: OK
- Chrome: OK
- Visual Studio (Windows): OK
- Connected device: OK
- Network resources: OK

## 8. Test rapide d'un projet Flutter

### 8.1 Creer un projet
```bash
flutter create demo_app
cd demo_app
```

### 8.2 Lancer sur une cible
```bash
flutter devices
flutter run -d chrome
```
ou
```bash
flutter run -d windows
```
ou (Android)
```bash
flutter run -d <android_device_id>
```

## 9. Maintenance utile

### 9.1 Mettre a jour Flutter
```bash
flutter upgrade
flutter doctor
```

### 9.2 Nettoyer un projet
```bash
flutter clean
flutter pub get
```

## 10. Depannage rapide

### Probleme: `Unable to locate Android SDK`
- Verifier `ANDROID_SDK_ROOT`
- Verifier `flutter config --android-sdk "C:\Android\Sdk"`
- Verifier la presence de `adb.exe` dans `C:\Android\Sdk\platform-tools`

### Probleme: `No valid Android SDK platforms found`
- Installer `platforms;android-36` et `build-tools;36.0.0` avec `sdkmanager`

### Probleme: `Cannot find Chrome executable`
- Verifier Chrome installe
- Definir `CHROME_EXECUTABLE`

### Probleme: commande non reconnue apres `setx`
- Fermer/reouvrir le terminal
- Reouvrir VS Code si necessaire

## 11. Commandes de reference
```bash
flutter --version
flutter doctor
flutter doctor -v
flutter devices
flutter emulators
flutter run
flutter build apk
flutter build web
flutter build windows
```
