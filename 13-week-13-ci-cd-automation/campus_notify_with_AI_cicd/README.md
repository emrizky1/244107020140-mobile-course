# Campus Notify

Campus Notify is a Flutter application for viewing campus announcements, saving notes, and chatting with an AI assistant.

## CI/CD workflow

The GitHub Actions workflow at `.github/workflows/flutter-ci.yml` runs on pushes and pull requests targeting `main`, and can also be started manually. It checks out the repository, installs Java 17 and stable Flutter, fetches dependencies, checks Dart formatting, runs static analysis and tests, and then builds Android release APK and app bundle files. Successful builds are uploaded as the `android-builds` artifact for seven days.


## Versioning

The current version in `pubspec.yaml` is `1.0.0+1`: app version `1.0.0`, build number `1`. The proposed next patch release is `1.0.1+2`. Increment the build number for every new upload, and tag a release commit (for example, `v1.0.1`) after its checks pass.

## Lab verification record

Local verification for the CI and artifact workflow changes:

- Dart formatting check: passed, 46 source and test files checked with no changes required.
- `flutter analyze --fatal-infos`: passed with no issues.
- `flutter test --coverage`: passed, all 33 tests passed.
- `flutter build apk --release`: passed; produced `build/app/outputs/flutter-apk/app-release.apk`.
- `flutter build appbundle --release`: passed; produced `build/app/outputs/bundle/release/app-release.aab`.

## Reflection

### What problem was detected automatically before changes were merged?

The workflow checks catch Dart formatting drift, static analysis errors and infos, and failing unit or widget tests before a pull request can be merged. The current project passed those checks locally; a deliberately failing change has not been used to demonstrate a red GitHub Actions run.

### What information would help investigate a failed build?

The failed workflow step and its complete log, the commit SHA and branch, the Flutter and Java versions, dependency resolution output, and the exact Gradle error would help reproduce and narrow down a failure. For artifact problems, confirm whether the APK and AAB files were created and whether the upload step found both paths.

### What still needs approval or manual review before a release?

Review the source changes and version, verify app configuration and permissions, test the signed build on supported devices, and obtain the release approval required by the project. Production signing material must be kept in restricted GitHub Actions secrets and only exposed to a protected release workflow. The current Android release build uses the debug signing configuration and is for build verification only; it is not ready to publish. The workflow does not upload to the Play Store.