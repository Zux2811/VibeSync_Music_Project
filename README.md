# VibeSync Music Project 🎵

A comprehensive music streaming application with Flutter mobile app, Node.js backend, and React admin dashboard.

## Project Structure

```
VibeSync_Music_Project/
├── music_app/                 # Flutter Mobile Application
│   ├── lib/                   # Dart source code
│   ├── android/               # Android native code
│   ├── ios/                   # iOS native code
│   ├── web/                   # Web platform
│   ├── windows/               # Windows platform
│   ├── linux/                 # Linux platform
│   ├── macos/                 # macOS platform
│   └── pubspec.yaml           # Flutter dependencies
│
├── music-app-backend/         # Node.js Backend API
│   ├── src/
│   │   ├── controllers/       # API controllers
│   │   ├── models/            # Database models
│   │   ├── routes/            # API routes
│   │   ├── middleware/        # Express middleware
│   │   ├── config/            # Configuration files
│   │   └── utils/             # Utility functions
│   ├── package.json           # Node dependencies
│   └── .env                   # Environment variables
│
└── admin-dashboard/           # React Admin Dashboard
    ├── src/
    │   ├── components/        # React components
    │   ├── pages/             # Page components
    │   ├── api/               # API integration
    │   ├── context/           # React context
    │   └── styles/            # CSS styles
    ├── package.json           # NPM dependencies
    └── vite.config.js         # Vite configuration
```

## Features

### Mobile App (Flutter)
- 🎵 Music streaming and playback
- [object Object] (Android, iOS, Web, Windows, Linux, macOS)
- 👤 User authentication and profiles
- ❤️ Favorites and playlists
- 💬 Comments and social features
- 🎁 Premium subscription support
- 🌙 Dark/Light theme support

### Backend (Node.js)
- 🔐 User authentication with JWT
- 🎵 Song management and streaming
- 📊 Admin controls
- 💳 Subscription management
- 📁 Playlist and folder management
- 💬 Comment system
- 📤 File upload with Cloudinary

### Admin Dashboard (React)
- 📊 Dashboard analytics
- 👥 User management
- 🎵 Song management and upload
- 📋 Report management
- 🔐 Admin authentication

## Getting Started

### Prerequisites
- Flutter SDK
- Node.js (v14 or higher)
- npm or yarn
- Git

### Installation

#### 1. Clone the repository
```bash
git clone https://github.com/Zux2811/VibeSync_Music_Project.git
cd VibeSync_Music_Project
```

#### 2. Setup Backend
```bash
cd music-app-backend
npm install
# Configure .env file with your settings
npm start
```

#### 3. Setup Admin Dashboard
```bash
cd admin-dashboard
npm install
npm run dev
```

#### 4. Setup Mobile App
```bash
cd music_app
flutter pub get
flutter run
```

## Environment Variables

### Backend (.env)
```
DATABASE_URL=your_database_url
JWT_SECRET=your_jwt_secret
CLOUDINARY_NAME=your_cloudinary_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
```

## Technologies Used

### Frontend (Mobile)
- Flutter
- Dart
- Provider (State Management)
- HTTP Client

### Backend
- Node.js
- Express.js
- Sequelize ORM
- PostgreSQL/MySQL
- JWT Authentication
- Cloudinary (File Storage)

### Admin Dashboard
- React
- Vite
- Axios
- CSS3

## API Documentation

The backend provides RESTful APIs for:
- Authentication (`/api/auth`)
- Songs (`/api/songs`)
- Playlists (`/api/playlists`)
- Users (`/api/users`)
- Comments (`/api/comments`)
- Subscriptions (`/api/subscriptions`)
- Admin (`/api/admin`)

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, email dev@vibesync.com or open an issue on GitHub.

---

**Made with ❤️ by VibeSync Team**

