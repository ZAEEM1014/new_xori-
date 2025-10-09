# Professional Flutter Social Media App Notification Server Development Prompt

## Project Overview
You are tasked with creating a comprehensive, production-ready Node.js/Express notification server for a Flutter social media application called "Xori". This server will handle all push notifications, maintain notification history, and provide APIs for notification management.

## Firebase Firestore Collections & Subcollections Structure

### Main Collections:

#### 1. `users` Collection
- **Document ID**: User UID
- **Fields**: `uid`, `username`, `email`, `profileImageUrl`, `createdAt`, `bio`, `personalityTraits`, `followersCount`, `followingCount`
- **Subcollections**:
  - `followers/` - Contains follower user documents
  - `following/` - Contains following user documents  
  - `chat_list/` - Contains contact documents for messaging
  - `savedReels/` - Contains saved reel references
  - `notification_settings/` - User notification preferences and push tokens

#### 2. `posts` Collection
- **Document ID**: Auto-generated
- **Fields**: `userId`, `username`, `userPhotoUrl`, `caption`, `hashtags`, `mediaUrls`, `mediaType`, `createdAt`, `likes`, `commentCount`, `shareCount`, `location`, `mentions`, `isDeleted`, `taggedUsers`
- **Subcollections**:
  - `likes/` - Contains like documents with userId and timestamp
  - `comments/` - Contains comment documents
  - `shares/` - Contains share documents

#### 3. `reels` Collection
- **Document ID**: Auto-generated
- **Fields**: `userId`, `username`, `userPhotoUrl`, `videoUrl`, `caption`, `likes`, `commentCount`, `shareCount`, `createdAt`, `isDeleted`
- **Subcollections**:
  - `likes/` - Contains like documents
  - `comments/` - Contains comment documents
  - `shares/` - Contains share documents

#### 4. `stories` Collection
- **Document ID**: Auto-generated
- **Fields**: `userId`, `username`, `userProfileImage`, `storyUrl`, `postedAt`, `expiresAt`, `viewedBy`, `likes`, `commentCount`
- **Subcollections**:
  - `likes/` - Contains like documents
  - `comments/` - Contains comment documents

#### 5. `messages` Collection
- **Document ID**: Auto-generated
- **Fields**: `senderId`, `receiverId`, `content`, `type`, `timestamp`, `isRead`, `replyToMessageId`, `mediaUrl`

#### 6. `notifications` Collection (To be created by server)
- **Document ID**: Auto-generated
- **Fields**: 
  - `recipientId` (string) - User who receives the notification
  - `senderId` (string) - User who triggered the notification
  - `type` (string) - Type of notification (like, comment, follow, post, reel, story)
  - `title` (string) - Notification title
  - `body` (string) - Notification content
  - `data` (object) - Additional data (postId, reelId, storyId, etc.)
  - `isRead` (boolean) - Read status
  - `createdAt` (timestamp) - When notification was created
  - `category` (string) - Category for grouping (social, content, message)

## Required Server Features

### 1. Push Notification System
- **Firebase Cloud Messaging (FCM) Integration**
- Support for Android, iOS, and Web push notifications
- Batch notification sending for efficiency
- Notification retry mechanism for failed deliveries
- Rich notifications with images and action buttons

### 2. Notification Types to Handle

#### Social Notifications (Store in Firestore):
- **Follow Notifications**: When someone follows/unfollows a user
- **Post Interactions**: Likes, comments, shares on posts
- **Reel Interactions**: Likes, comments, shares on reels  
- **Story Interactions**: Likes, comments on stories
- **Mentions**: When user is tagged in posts/comments

#### Content Notifications (Store in Firestore):
- **New Post**: When followed users create new posts
- **New Reel**: When followed users create new reels
- **New Story**: When followed users create new stories

#### Message Notifications (Push Only - DO NOT store in Firestore):
- **New Message**: Instant messaging notifications
- **Message Reactions**: When someone reacts to messages
- **Message Replies**: When someone replies to messages

### 3. Core API Endpoints Required

#### Notification Management:
- `POST /api/notifications/send` - Send push notification
- `GET /api/notifications/:userId` - Get user notifications (paginated)
- `PUT /api/notifications/:notificationId/read` - Mark notification as read
- `PUT /api/notifications/:userId/read-all` - Mark all notifications as read
- `DELETE /api/notifications/:notificationId` - Delete notification
- `GET /api/notifications/:userId/unread-count` - Get unread notification count

#### User Token Management:
- `POST /api/users/:userId/push-token` - Update user's FCM push token
- `PUT /api/users/:userId/notification-settings` - Update notification preferences
- `GET /api/users/:userId/notification-settings` - Get notification preferences
- `POST /api/users/:userId/device-info` - Update device information

#### Webhook Endpoints for Firestore Triggers:
- `POST /webhook/post-liked` - Handle post like notifications
- `POST /webhook/post-commented` - Handle post comment notifications
- `POST /webhook/reel-liked` - Handle reel like notifications
- `POST /webhook/reel-commented` - Handle reel comment notifications
- `POST /webhook/story-liked` - Handle story like notifications
- `POST /webhook/user-followed` - Handle follow notifications
- `POST /webhook/new-message` - Handle message notifications (push only)

### 4. Notification Settings Schema
Each user should have customizable notification settings:
```json
{
  "pushToken": "fcm_token_here",
  "deviceInfo": {
    "platform": "android|ios|web",
    "deviceId": "unique_device_id",
    "appVersion": "1.0.0"
  },
  "preferences": {
    "posts": {
      "likes": true,
      "comments": true,
      "shares": true
    },
    "reels": {
      "likes": true,
      "comments": true,
      "shares": true
    },
    "stories": {
      "likes": true,
      "comments": true
    },
    "social": {
      "follows": true,
      "mentions": true
    },
    "messages": {
      "newMessages": true,
      "messageReplies": true
    },
    "content": {
      "newPosts": true,
      "newReels": true,
      "newStories": true
    }
  },
  "quietHours": {
    "enabled": false,
    "startTime": "22:00",
    "endTime": "08:00",
    "timezone": "UTC"
  }
}
```

### 5. Technical Requirements

#### Server Technology:
- Node.js with Express.js framework
- TypeScript for type safety
- Firebase Admin SDK for Firestore and FCM
- Redis for caching and rate limiting
- Bull Queue for background job processing
- Winston for logging
- Joi for input validation
- Helmet for security headers
- CORS enabled for Flutter web support

#### Database & Caching:
- Use Firebase Firestore as primary database
- Redis for caching frequently accessed data (user preferences, push tokens)
- Implement connection pooling and retry mechanisms

#### Security Features:
- API key authentication for webhook endpoints
- Rate limiting (per user and per endpoint)
- Input validation and sanitization
- CORS policy configuration
- Security headers with Helmet
- Request logging and monitoring

#### Performance & Scalability:
- Asynchronous notification processing with queues
- Batch processing for multiple notifications
- Database query optimization
- Caching strategies for user preferences
- Graceful error handling and retries

### 6. Notification Content Templates
Create dynamic notification templates for different scenarios:

#### Like Notifications:
- Post: "{username} liked your post"
- Reel: "{username} liked your reel"
- Story: "{username} liked your story"

#### Comment Notifications:
- Post: "{username} commented on your post: {comment_preview}"
- Reel: "{username} commented on your reel: {comment_preview}"
- Story: "{username} replied to your story: {comment_preview}"

#### Follow Notifications:
- "{username} started following you"

#### Content Notifications:
- "{username} shared a new post"
- "{username} shared a new reel"
- "{username} posted a new story"

#### Message Notifications (Push Only):
- "{username}: {message_preview}"
- "{username} sent you a photo"
- "{username} sent you a video"

### 7. Error Handling & Monitoring
- Comprehensive error logging
- Failed notification retry mechanism
- Health check endpoints
- Performance monitoring
- Invalid token cleanup (for expired FCM tokens)

## Deliverables Required

### 1. Complete Server Implementation
- Fully functional Node.js/Express server
- All API endpoints implemented
- Webhook handlers for Firestore triggers
- FCM integration for push notifications
- Database schemas and models

### 2. API Documentation
- Comprehensive API documentation with examples
- Request/response schemas
- Error codes and messages
- Authentication requirements
- Rate limiting information

### 3. Flutter Integration Guide
- Detailed implementation guide for Flutter integration
- Code examples for API calls
- FCM token management in Flutter
- Notification handling in Flutter app
- Firebase Cloud Functions setup (if needed)

### 4. Deployment Instructions
- Docker containerization
- Environment configuration
- Production deployment guide
- Monitoring and logging setup
- Security checklist

### 5. Testing Suite
- Unit tests for all API endpoints
- Integration tests for notification flows
- Performance tests for concurrent users
- Mock FCM server for testing

## Expected Code Quality Standards
- TypeScript with strict type checking
- Comprehensive error handling
- Clean, modular, and maintainable code
- Proper separation of concerns
- Detailed inline documentation
- Following REST API best practices
- Implementing proper HTTP status codes
- Consistent naming conventions

## Additional Notes
- The server should be production-ready and scalable
- Implement proper logging for debugging and monitoring
- Consider implementing notification scheduling for future features
- Ensure compatibility with Firebase Security Rules
- Implement proper database indexing for performance
- Create comprehensive README with setup instructions

Please provide a complete, professional implementation that can be deployed to production immediately, along with clear documentation and integration guidelines for the Flutter application.
