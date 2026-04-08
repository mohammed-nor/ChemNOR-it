# ChemNOR Store Publishing Checklist

## Pre-Launch Checklist

### 1. Store Listing Details
- [ ] Update `store_listing.yaml` or `store_listing_json.json` with accurate information
- [ ] Replace placeholder URLs (privacy policy, website, support)
- [ ] Update developer name and contact email
- [ ] Review and finalize app description
- [ ] Create all required screenshots (5-8 recommended)
- [ ] Create feature graphic (1024x500px for Google Play)
- [ ] Create app icon (512x512px, rounded corners)

### 2. Google Play Store Setup
- [ ] Create Google Play Developer account ($25 one-time fee)
- [ ] Set up Google Play Console
- [ ] Create app entry with package name: `com.chemnor.app`
- [ ] Upload signed APK or AAB (Android App Bundle)
- [ ] Add store listing (title, description, screenshots)
- [ ] Set content rating (complete questionnaire)
- [ ] Add privacy policy and terms of service links
- [ ] Set app category and content rating
- [ ] Verify app quality (check for warnings in Play Console)
- [ ] Review and submit app for review

### 3. Apple App Store Setup
- [ ] Create Apple Developer account ($99/year)
- [ ] Set up App Store Connect account
- [ ] Create app bundle with unique identifier
- [ ] Generate provisioning profiles and certificates
- [ ] Build iOS app using Xcode
- [ ] Add store listing (title, description, screenshots)
- [ ] Set app category and age rating
- [ ] Add privacy policy link
- [ ] Add keywords and promotional text
- [ ] Add app preview video (optional)
- [ ] Submit for review

### 4. App Requirements
- [ ] Verify API keys are configured correctly
  - [ ] Google Generative AI API key
  - [ ] ChemNOR API key (if applicable)
  - [ ] Gemini API key (if applicable)
- [ ] Test all features on actual devices
- [ ] Test compound search functionality
- [ ] Test AI chat functionality
- [ ] Test chat history saving/loading
- [ ] Test settings persistence
- [ ] Test on minimum supported OS version (Android 6.0, iOS 11.0+)

### 5. Content & Assets
- [ ] Prepare screenshots for both Android and iOS
  - Android: 1080x1920px (minimum)
  - iOS: 1290x2796px for iPhone (minimum)
- [ ] Create promotional graphics
- [ ] Prepare app icon variations
- [ ] Write concise version release notes
- [ ] Add changelog for first release

### 6. Privacy & Security
- [ ] Create and publish privacy policy
- [ ] Create and publish terms of service
- [ ] Ensure API keys are not hardcoded
- [ ] Use environment variables or secure storage
- [ ] Verify app doesn't collect unnecessary data
- [ ] Test offline functionality (if applicable)
- [ ] Ensure HTTPS is used for all API calls

### 7. Version & Build Numbers
- [ ] Update version in `pubspec.yaml`: `1.0.0`
- [ ] Update build number: `1`
- [ ] Ensure version is consistent across Android and iOS
- [ ] Tag git release: `v1.0.0`

### 8. Final Testing
- [ ] Run `flutter analyze` (check for lint issues)
- [ ] Run `flutter test` (all tests passing)
- [ ] Build release APK: `flutter build apk --release`
- [ ] Build release iOS: `flutter build ios --release`
- [ ] Test on real device (both Android and iOS if possible)
- [ ] Check for performance issues
- [ ] Verify all permissions are declared
- [ ] Test error handling and edge cases

### 9. Publishing Workflow

#### For Google Play Store:
```bash
# Build release APK
flutter build apk --release

# Or build Android App Bundle (recommended)
flutter build appbundle --release

# Upload to Google Play Console
# -> Internal testing (optional)
# -> Closed testing / Beta
# -> Production (once confident)
```

#### For Apple App Store:
```bash
# Build iOS release
flutter build ios --release

# Archive in Xcode and upload via App Store Connect
# Or use Xcode command line tools
```

### 10. Post-Launch
- [ ] Monitor app reviews and ratings
- [ ] Watch for crash reports in Play Console
- [ ] Monitor TestFlight feedback (Apple)
- [ ] Set up analytics (Segment, Firebase, etc.)
- [ ] Plan update schedule for bug fixes
- [ ] Engage with user reviews and feedback
- [ ] Set version for next release

## Important Contacts
- **Google Support**: support.google.com/googleplay
- **Apple Support**: developer.apple.com/contact
- **Store Listing Files**: 
  - YAML format: `store_listing.yaml`
  - JSON format: `store_listing_json.json`

## Notes
- Review both store policies thoroughly before submission
- Some features may require additional approvals
- Allow 24-48 hours for Google Play review
- Allow 2-5 business days for Apple App Store review
- Watch for rejection reasons - they provide detailed feedback
