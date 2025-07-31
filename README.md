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
   - Follow setup in [`lib/firebase_options.dart`](./lib/firebase_options.dart)
   - Add Firebase project credentials for each platform.

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

## Contributing

Pull requests and issues are welcome! For major changes, open an issue first to discuss what you’d like to change.

## License

MIT

## References

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.flutter.dev/docs/overview)
