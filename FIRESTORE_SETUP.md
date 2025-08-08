# Firestore Security Rules for Blog Project

## Copy these rules to your Firestore Database Rules in Firebase Console

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      // Users can read their own data and other users' public data
      allow read: if true;
      // Users can only write to their own document
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Blogs collection
    match /blogs/{blogId} {
      // Anyone can read published blogs
      allow read: if resource.data.isDraft == false || 
                     (request.auth != null && request.auth.uid == resource.data.authorId);
      
      // Only authenticated users can create blogs
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.authorId;
      
      // Only the author can update their own blogs
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.authorId;
      
      // Only the author can delete their own blogs
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.authorId;
    }
    
    // Comments collection
    match /comments/{commentId} {
      // Anyone can read comments
      allow read: if true;
      
      // Only authenticated users can create comments
      allow create: if request.auth != null && 
                       request.auth.uid == request.resource.data.authorId;
      
      // Only the author can update their own comments
      allow update: if request.auth != null && 
                       request.auth.uid == resource.data.authorId;
      
      // Only the author can delete their own comments
      allow delete: if request.auth != null && 
                       request.auth.uid == resource.data.authorId;
    }
    
    // Notifications collection (if you add this later)
    match /notifications/{notificationId} {
      // Users can only read their own notifications
      allow read: if request.auth != null && 
                     request.auth.uid == resource.data.userId;
      
      // System can create notifications, users can update read status
      allow write: if request.auth != null && 
                      request.auth.uid == resource.data.userId;
    }
  }
}
```

## How to Apply These Rules:

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to Firestore Database
4. Click on "Rules" tab
5. Replace the existing rules with the rules above
6. Click "Publish"

## Database Structure Overview:

### Users Collection (`/users/{userId}`)
- uid: string
- email: string  
- username: string (unique)
- name: string
- photoURL: string
- bio: string
- createdAt: timestamp
- lastLoginAt: timestamp
- followersCount: number
- followingCount: number  
- postsCount: number
- interests: array of strings
- isVerified: boolean
- profileViews: number
- totalLikesReceived: number
- totalBlogViews: number

### Blogs Collection (`/blogs/{blogId}`)
- authorId: string
- authorUsername: string
- authorPhotoURL: string
- authorName: string
- title: string
- content: string (HTML)
- imageURL: string
- category: string
- tags: array of strings
- isDraft: boolean
- createdAt: timestamp
- updatedAt: timestamp
- publishedAt: timestamp
- likesCount: number
- commentsCount: number
- viewsCount: number
- featured: boolean
- likedBy: array of user IDs
- readTime: number (minutes)

### Comments Collection (`/comments/{commentId}`)
- postId: string
- authorId: string
- authorUsername: string
- authorPhotoURL: string
- authorName: string
- content: string
- createdAt: timestamp
- updatedAt: timestamp
- likesCount: number
- likedBy: array of user IDs
- parentCommentId: string (for replies)
- replies: array of comment IDs

## Indexes to Create in Firestore:

Go to Firestore > Indexes and create these composite indexes:

1. **blogs** collection:
   - isDraft (Ascending) + publishedAt (Descending)
   - isDraft (Ascending) + category (Ascending) + publishedAt (Descending)
   - authorId (Ascending) + isDraft (Ascending) + updatedAt (Descending)
   - authorId (Ascending) + isDraft (Ascending) + publishedAt (Descending)
   - featured (Ascending) + publishedAt (Descending)
   - isDraft (Ascending) + likesCount (Descending)

2. **comments** collection:
   - postId (Ascending) + parentCommentId (Ascending) + createdAt (Ascending)

3. **users** collection:
   - username (Ascending) - for search functionality

Most of these indexes will be automatically suggested by Firebase when you run queries.
