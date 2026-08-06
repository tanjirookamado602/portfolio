# Muhammad Assad Ullah - Portfolio

A fully responsive, dynamic portfolio website built with Flutter and Firebase. This project showcases my skills, projects, certifications, and hackathon achievements.

## 🚀 Live Demo
[https://muhammad-assadullah.vercel.app](https://muhammad-assadullah.vercel.app)

## 🛠 Tech Stack
- **Framework**: Flutter (Web & Mobile)
- **Backend / Database**: Firebase (Firestore, Auth)
- **Deployment**: Vercel
- **Languages**: Dart, HTML/CSS (for web-specific integrations)

## ✨ Features
- **Dynamic Content**: All sections (Projects, Skills, Hackathons, etc.) are managed via a built-in Admin Panel backed by Firestore.
- **Responsive Design**: Optimized for Desktop, Tablet, and Mobile.
- **Interactive UI**: Custom animations, hover effects, and glassmorphism UI elements.
- **Platform Optimized**: Uses HTML-native image rendering on Web to bypass CORS issues with Google Drive images.

## 📂 Project Structure
- `lib/screens`: Individual pages (Home, Projects, About, Contact, etc.)
- `lib/admin`: Admin panel for content management.
- `lib/services`: Firebase and content management services.
- `lib/widgets`: Reusable UI components (ProjectCard, AnimatedBackground, etc.)

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.x or later)
- Firebase Account (configured in `lib/firebase_options.dart`)

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/assassinaj602/muhammad-assadullah.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run -d chrome
   ```

## 📝 Admin Panel
Access the admin panel by navigating to `/admin` (or clicking the button in the footer/header). Usage requires authentication configured in Firebase.

## 📄 License
This project is open source and available under the [MIT License](LICENSE).
