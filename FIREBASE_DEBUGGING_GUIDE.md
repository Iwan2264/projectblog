# Firebase Setup & Troubleshooting Guide

## Issue 1: Firestore Database Setup

### Steps to Set Up Firestore in Firebase Console:

1. **Go to Firebase Console** → Your Project → Firestore Database
2. **Create Database** with these settings:
   - **Mode**: Production mode (uses security rules)
   - **Location**: us-east1 (to match your Storage region)
   - **Database ID**: (default) - leave as default

### Deploy Security Rules:
1. Go to Firestore Database → Rules tab
2. Copy and paste the corrected rules from `firestore.rules`
3. Click "Publish"

**Key Fix**: Changed `isPublished` to `isDraft` to match your data model.

---

## Issue 2: Save Draft / Publish Not Working

### Root Cause Analysis:
The Create Post page IS properly connected to BlogPostController. If buttons aren't working, check:

### 1. **Firebase Authentication**
Make sure you're logged in:
```dart
// In your app, check if user is authenticated
FirebaseAuth.instance.currentUser != null
```

### 2. **Check Firebase Connection**
Verify Firebase is initialized and connected:
- Check `firebase_options.dart` exists
- Verify `google-services.json` is in `/android/app/`

### 3. **Debug the Button Actions**
The buttons should trigger:
- `_controller.saveDraft()` for Save Draft
- `_controller.publishPost()` for Publish

### 4. **Check Console for Errors**
Run the app with Flutter console open to see any error messages.

---

## Issue 3: Drafts Without Images Not Showing

### Fixed in `draft_card.dart`:
- Updated icon from `Icons.draft_outlined` to `Icons.drafts_outlined`
- Improved image placeholder logic
- Better error handling for missing images

---

## Testing Steps:

### Test 1: Save Draft
1. Open Create Post page
2. Add title: "Test Draft"
3. Add some content
4. Select category
5. Click "Save Draft"
6. ✅ Should see "Draft saved successfully" message
7. ✅ Should appear in Home → Drafts tab

### Test 2: Publish Post
1. Create or edit a draft
2. Add cover image (optional)
3. Complete title, content, category
4. Click "Publish" 
5. ✅ Should see "Post published successfully" message
6. ✅ Should appear in Home → Published tab

### Test 3: Debug Mode
If still not working, add this debug code to BlogPostController:

```dart
// In saveDraft method, add at the beginning:
print('DEBUG: saveDraft called');
print('DEBUG: Title: ${titleController.text}');
print('DEBUG: Content length: ${htmlContent.value.length}');
print('DEBUG: Category: ${selectedCategory.value}');
print('DEBUG: User: ${_authController.userModel.value?.uid}');
```

---

## Common Issues & Solutions:

### Issue: "Authentication Error"
**Solution**: Make sure user is properly logged in
```dart
// Check in your app
print('Current user: ${FirebaseAuth.instance.currentUser?.uid}');
```

### Issue: "Permission denied" 
**Solution**: Deploy the corrected Firestore rules

### Issue: Buttons not responsive
**Solution**: Check if controller is properly initialized in CreatePostPage

### Issue: No data in Firestore
**Solution**: Check Firestore console → Data tab → blogs collection

---

## Expected Firestore Data Structure:

### Drafts:
```json
{
  "authorId": "user123",
  "title": "My Draft",
  "content": "<p>Draft content</p>",
  "isDraft": true,
  "category": "Tech",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

### Published Posts:
```json
{
  "authorId": "user123", 
  "title": "My Post",
  "content": "<p>Published content</p>",
  "isDraft": false,
  "category": "Tech",
  "publishedAt": "timestamp",
  "likesCount": 0,
  "viewsCount": 0
}
```
