# 🧪 Testing Guide for Your Blog App

## Your User Info for Testing:
- **UID**: `QTEruoKFSOWDitvVF6ZuYe1fPJs1`
- **Email**: `wansaf05@gmail.com`
- **Username**: `safwan`
- **Name**: `Safwan`

---

## ✅ Firebase Setup Complete!

### **Firestore & Storage Rules Deployed Successfully**
- ✅ Firestore rules deployed
- ✅ Storage rules deployed  
- ✅ firebase.json configured
- ✅ Project linked to `projectblog001`

---

## 🧪 Step-by-Step Testing

### **Test 1: Save Draft**
1. **Open Create Post page**
2. **Add the following:**
   ```
   Title: "My First Test Draft"
   Content: "This is a test draft to verify saving works."
   Category: Select "Tech" 
   Cover Image: (optional)
   ```
3. **Click "Save Draft"**
4. **Expected Results:**
   - ✅ See console log: `🔍 DEBUG: saveDraft called`
   - ✅ See console log: `✅ DEBUG: Draft saved to Firestore with ID: [some-id]`
   - ✅ See green snackbar: "Draft saved successfully"
   - ✅ Draft appears in Home → Drafts tab

### **Test 2: Publish Post**
1. **Either create new post or edit existing draft**
2. **Complete all fields:**
   ```
   Title: "My First Blog Post"
   Content: "This is my first published blog post!"
   Category: Select any category
   Cover Image: Add an image
   ```
3. **Click "Publish"**
4. **Expected Results:**
   - ✅ See console log: `🚀 DEBUG: publishPost called`
   - ✅ See console log: `🎉 DEBUG: Post published to Firestore with ID: [some-id]`
   - ✅ See green snackbar: "Post published successfully"
   - ✅ Post appears in Home → Published tab

### **Test 3: Verify in Firebase Console**
1. **Go to:** https://console.firebase.google.com/project/projectblog001/firestore
2. **Check Collections:**
   - ✅ `blogs` collection exists
   - ✅ Documents have `authorId: "QTEruoKFSOWDitvVF6ZuYe1fPJs1"`
   - ✅ Drafts have `isDraft: true`
   - ✅ Published posts have `isDraft: false`

---

## 🔧 If Something Doesn't Work:

### **Check Debug Console:**
Look for these debug messages in Flutter console:
```
🔍 DEBUG: saveDraft called
🔍 DEBUG: Title: "My First Test Draft"
🔍 DEBUG: Content length: 45
🔍 DEBUG: Category: "Tech"
🔍 DEBUG: Current user: QTEruoKFSOWDitvVF6ZuYe1fPJs1
✅ DEBUG: Draft saved to Firestore with ID: xyz789
```

### **Common Issues:**

**Issue: "Authentication Error"**
- **Solution**: Make sure you're logged in with `wansaf05@gmail.com`

**Issue: "Permission denied"**
- **Solution**: Rules are now deployed, should work

**Issue: No debug logs appearing**
- **Solution**: Check if `BlogPostController` is properly initialized

**Issue: Buttons not responding**
- **Solution**: Check if category is selected (required field)

---

## 📱 CLI Commands You Now Have:

### **Deploy Rules (anytime you update them):**
```bash
firebase deploy --only firestore:rules,storage
```

### **Deploy just Firestore rules:**
```bash
firebase deploy --only firestore:rules
```

### **Deploy just Storage rules:**
```bash
firebase deploy --only storage
```

### **Check Firebase project:**
```bash
firebase projects:list
```

---

## 🎯 What Should Work Now:

1. ✅ **Save Draft** - Creates document in Firestore with `isDraft: true`
2. ✅ **Publish Post** - Creates/updates document with `isDraft: false`
3. ✅ **Cover Images** - Uploads to Firebase Storage
4. ✅ **View Drafts** - Shows in Home → Drafts tab
5. ✅ **View Published** - Shows in Home → Published tab
6. ✅ **Security** - Only you can access your drafts
7. ✅ **Duplicate Prevention** - Multiple clicks handled properly

## 🚀 Ready to Test!

Your blog app should now work perfectly. Try creating a draft and publishing a post!
