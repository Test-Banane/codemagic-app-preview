Run `app_preview post --gh_token $GITHUB_PAT` after building your apps.

Here is a full `codemagic.yaml` as an example:
```yaml
# This is example for using the codemagic_app_preview package in a
# `codemagic.yaml`.

workflows:
  app_preview:
    name: app_preview
    environment:
      flutter: default
      groups:
        # Adding environment group "github" which includes the GITHUB_PAT
        # variable.
        - "github"
        # Adding environment group "appstore_credentials" to sign iOS apps.
        - appstore_credentials
    triggering:
      events:
        - pull_request
      cancel_previous_builds: true
    working_directory: packages/app_preview_example
    scripts:
      # Sign with the type "IOS_APP_ADHOC". See more information about code
      # signing: https://docs.codemagic.io/yaml-code-signing/signing-ios/
      - name: Sign iOS
        script: |
          keychain initialize
          app-store-connect fetch-signing-files "io.nilsreichardt.codemagicapppreviewexample" --type IOS_APP_ADHOC --create
          keychain add-certificates
          xcode-project use-profiles
      - name: Fetch dependencies
        script: flutter pub get
      - name: Build APK (Android)
        script: flutter build apk
      - name: Build IPA (iOS)
        # Don't forget the "export-options" argument.
        script: flutter build ipa --export-options-plist=/Users/builder/export_options.plist
    # Add the paths to the APK.
    artifacts:
      - build/**/outputs/apk/**/*.apk
      - build/ios/ipa/*.ipa
    publishing:
      scripts:
        # Adding the path to the Dart SDK to PATH to be able to use `dart`
        # commands and commands of Dart packages. 
        - name: Add Dart SDK to PATH
          script: |
            echo PATH="$PATH":"$FLUTTER_ROOT/.pub-cache/bin" >> $CM_ENV
            echo PATH="$PATH":"$FLUTTER_ROOT/bin" >> $CM_ENV
        - name: Post App Preview
          script: |
            dart pub global activate -s path ../codemagic_app_preview
            app_preview post --gh_token $GITHUB_PAT
```