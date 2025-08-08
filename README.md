# ProjectBlog

A cross-platform blog platform built with Flutter and Firebase. Users can create, publish, and manage blog posts, view analytics, and interact (like) with other posts.

## Features

- User authentication (Firebase Auth)
- User profiles (Firestore)
- Blog post creation, editing, deletion
- Upload images for blogs and profile pictures (Firebase Storage)
- Like/unlike blog posts
- Recent feed, author feed, and liked blogs
- Blog search (by title/content)
- Blog analytics (views, likes, posts count)
- Secure and scalable database structure

## Technologies

- **Flutter** (Dart)
- **Firebase** (Firestore, Storage, Auth)
- **HTML** (web build)
- **C++ / CMake / Swift / C** (native platform support)

## Database Structure

See [`DATABASE_STRUCTURE.md`](./DATABASE_STRUCTURE.md) for full details on Firestore collections, security rules, and best practices.

## Getting Started

1. **Clone the repository**  
   `git clone https://github.com/Iwan2264/projectblog.git`

2. **Install dependencies**  
   `flutter pub get`

3. **Configure Firebase**  
   - Create a `firebase_options_dev.dart` file based on the template in the repository
   - Add your actual Firebase API keys to this file
   - This file should NOT be committed to version control (it's in .gitignore)
   - See "Firebase Configuration Security" section below for more details

4. **Run the app**  
   - Mobile: `flutter run`
   - Web: `flutter run -d chrome`

## Folder Structure

- `lib/`
  - `services/database_service.dart` – All database and storage operations.
  - `controllers/` – State management and business logic.
  - `models/` – Data models (User, Blog, Like, etc.)
  - `firebase_options.dart` – Multi-platform Firebase configuration.

## Security

- Firestore rules restrict updates/creates/deletes to authenticated users.
- Blogs can be read only if published or by the author.

## Firebase Configuration Security

To protect your Firebase API keys and configuration:

1. **Never commit real API keys to public repositories**
   - The repository version of `firebase_options.dart` contains placeholder keys

2. **Local Development Setup**
   - Create a `lib/firebase_options_dev.dart` file (based on the provided template)
   - Add your actual API keys to this file
   - This file is listed in `.gitignore` to prevent accidental commits

3. **If you accidentally exposed API keys:**
   - Rotate (regenerate) the affected keys in Google Cloud Console
   - Update your local `firebase_options_dev.dart` with the new keys
   - Consider adding API key restrictions in Google Cloud Console

## Contributing

Pull requests and issues are welcome! For major changes, open an issue first to discuss what you’d like to change.

## License

MIT

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/docs/overview)
