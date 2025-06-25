# 🎬 Cinemood

**Cinemood** is a Flutter-based movie review and discovery platform that allows users to browse popular films, read details, submit reviews, and manage their own movie preferences — powered by Firebase Authentication and Firestore.

---

## 🚀 Features

### 🔐 Authentication
- **Firebase Email & Password Login**
- **Register and Login flows**
- **Email verification before access to app features**
- **Secure logout**

### 📽️ Movie Discovery
- Browse **popular movies**
- View movie **titles, posters, genres, release dates**, and **ratings**
- Movie data powered by [TMDb API](https://www.themoviedb.org/documentation/api)

### 📝 Reviews System
- View all reviews posted by users
- Write and submit reviews for any movie
- Reviews stored in **Firebase Firestore**
- Each review includes:
  - Movie Title
  - Review Text
  - Author info
  - Timestamp

### 🙋‍♂️ User Profile
- View logged-in user's email
- View your own reviews in **My Reviews** section
- Only verified users can write reviews

## ☁️ Backend & Database (Firebase)

- 🔐 **Firebase Authentication** – Email/Password sign-in with email verification  
- 🗂️ **Cloud Firestore (NoSQL Database)** – Stores structured data like reviews, user info, timestamps  
- 🗄️ **Firebase Storage** – Stores media files such as movie posters or profile images  
- 🌐 **Firebase Hosting** – Used to deploy the web version of the app

---

## 📷 Screenshots (Optional)
Add screenshots of your Login screen, Movie list, Review screen, etc.

---

## 🛠️ Tech Stack

| Technology     | Purpose                    |
|----------------|----------------------------|
| Flutter        | UI Framework               |
| Dart           | Programming Language       |
| Firebase Auth  | User Authentication        |
| Firebase Firestore | Database for reviews    |
| Firebase Hosting | Web deployment            |
| TMDb API       | Movie data source          |

---

## 📦 Installation

```bash
git clone https://github.com/atik-7866/Flutterwoc.git
cd Flutterwoc
flutter pub get
flutter run
