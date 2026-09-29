# NewsMorocco App 🇲🇦

Android news application for NewsMorocco.

## Features
- Moroccan news
- Moroccan sports shown first
- General news
- Economy
- Technology
- Search
- Pull-to-refresh
- Opens full articles in the browser
- Online data from the NewsMorocco website
- No account or login

## News source
The app reads the live feed from:
https://smail1983.github.io/Nwesmomroco/news.json

When the custom NewsMorocco domain is ready, this URL can be changed.

## Local setup
Install the latest stable Flutter SDK and Android Studio, then:
flutter pub get
flutter run

For release:
flutter build appbundle --release
