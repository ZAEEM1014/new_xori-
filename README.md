# Xori - Social Media Flutter App

A modern social media application built with Flutter, featuring image/video sharing, stories, and real-time interactions.

## 🚀 Features

### ✅ Completed Features
- **User Authentication** - Firebase Auth with email/password
- **Post Creation** - Upload images and videos with captions and hashtags
- **Media Upload** - Cloudinary integration for image/video storage
- **Real-time Database** - Firestore for data management
- **User Profiles** - Complete profile management
- **Navigation** - Bottom navigation with multiple screens
- **Onboarding** - Welcome flow for new users

### 📱 Screens
- **Onboarding** - App introduction
- **Authentication** - Login/Signup
- **Home Feed** - Posts and stories
- **Add Post** - Create posts with media upload
- **Search** - Discover content
- **Reels** - Short video content
- **Profile** - User profile management
- **Chat** - Messaging functionality

## 🛠 Tech Stack

- **Frontend**: Flutter with GetX state management
- **Backend**: Firebase (Auth, Firestore)
- **Media Storage**: Cloudinary
- **State Management**: GetX
- **Architecture**: Clean Architecture with MVC pattern

## 📋 Project Structure

```
lib/
├── config/          # Configuration files
├── constants/       # App constants and assets
├── data/           # Demo data
├── models/         # Data models
├── modules/        # Feature modules
│   ├── auth/       # Authentication
│   ├── add_post/   # Post creation ✅ WORKING
│   ├── home/       # Home feed
│   ├── profile/    # User profiles
│   └── ...
├── routes/         # App routing
├── services/       # Business logic services
└── widgets/        # Reusable UI components
```

## 🎯 Key Implemented Features

### Add Post Functionality ✅
- **Image/Video Picker** - Camera and gallery support
- **Media Upload** - Cloudinary integration
- **Post Creation** - Complete post workflow
- **Form Validation** - User input validation
- **Loading States** - Upload progress indicators
- **Error Handling** - Comprehensive error management

### Post Model & Service ✅
- **Post Model** - Complete data structure
- **PostService** - Database operations
- **CRUD Operations** - Create, read, update, delete posts
- **Real-time Streams** - Live data updates

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (>=3.0.0)
- Firebase project setup
- Cloudinary account for media storage

### Installation

1. Clone the repository
```bash
git clone <repository-url>
cd xori-master
```

2. Install dependencies
```bash
flutter pub get
```

3. Configure Firebase
- Add your `google-services.json` (Android)
- Add your `GoogleService-Info.plist` (iOS)
- Update Firebase configuration in `main.dart`

4. Configure Cloudinary
- Update `lib/config/cloudinary_config.dart` with your credentials

5. Run the app
```bash
flutter run
```

## 📱 Permissions

### Android
- Camera access
- Storage read/write
- Internet access

### iOS
- Camera usage
- Photo library access
- Microphone access (for video recording)

## 🏗 Architecture

The app follows **Clean Architecture** principles with:
- **GetX** for state management and dependency injection
- **Repository pattern** for data management
- **Service layer** for business logic
- **Model-View-Controller** structure

## 🎨 UI/UX

- **Material Design 3** compliance
- **Custom gradient themes**
- **Responsive design**
- **Smooth animations**
- **Modern UI components**

## 📊 Current Status

- ✅ **Upload Functionality**: Complete and working
- ✅ **Authentication**: Implemented
- ✅ **Database Integration**: Firestore setup
- ✅ **Media Upload**: Cloudinary integration
- 🔄 **Feed Display**: In development
- 🔄 **Chat System**: Basic structure
- 🔄 **Stories**: UI ready

## 🤝 Contributing

1. Fork the project
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License.

## 📞 Contact

For any questions or support, please reach out to the development team.
