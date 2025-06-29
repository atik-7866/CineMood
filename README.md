# 🎬 CineMood

**CineMood** is a cross-platform movie discovery and review app built using **Flutter** and **Firebase**. It allows users to browse movies by category, search using text or voice, submit and manage reviews, and maintain a personal wishlist. Authenticated users can log in via email or Google, and enjoy a smooth experience with features like swipe-based movie navigation and real-time username syncing.

Live :  https://registeration-988d7.web.app

---

## 🚀 Features

### 🔐 Authentication
- Sign up & login via **Email/Password**
- **Google Sign-In** supported (with auto-link if email Already Registered)
- Email verification required before accessing features

### 📽️ Movie Discovery
- Browse curated movie categories via **RapidAPI**
- View full movie details: poster, title, overview, rating, genre, release year
- **Swipe left/right** to seamlessly move between movies

### 🔎 Search & Voice Search
- Search movies using text (via **OMDb API**)
- Speak movie titles with built-in **voice search**

### 📝 Reviews
- Submit reviews for any movie once logged in
- Reviews show username, movie title, and timestamp
- Changing your **username updates it in all your past reviews** automatically

### 💖 Wishlist
- Add movies to your **personal wishlist**
- Wishlist is linked to your user account and securely stored
- View and manage wishlist items in a dedicated section

### 👤 Profile
- View and update your profile
- See your submitted reviews in **My Reviews**
- - See your submitted reviews in **My Wishlist**
- Changing your username updates all past reviews
- Changing your password with security
- 

---

## 🛠️ Tech Stack

| Technology        | Purpose                                               |
|-------------------|--------------------------------------------------------|
| **Flutter**       | UI development across Android, iOS, Web               |
| **Dart**          | Programming language used in Flutter                  |
| **Firebase Auth** | Secure user authentication (Email/Password, Google)  |
| **Firestore**     | NoSQL database for reviews, wishlists, user profiles |
| **Firebase Hosting** | Web deployment                                     |
| **Firebase Storage** | (Optional) for media files like posters or avatars |
| **OMDb API**      | Text-based & voice-based movie search                |
| **RapidAPI**      | Category-wise movie listings (e.g., Trending, Horror) |

---

## ☁️ Backend & Database (Firebase,NoSQL)

- 🔐 **Firebase Authentication** – Login with Email/Password and Google  
- 🗂️ **Cloud Firestore (NoSQL Database)** – Review data, wishlists, usernames  
- 🗄️ **Firebase Storage** – Optional use for images/posters  
- 🌐 **Firebase Hosting** – Web version deployment of the app  

---

## 🧑‍💻 Developed By

**👤 Atik Vohra**  
🔗 [GitHub](https://github.com/atik-7866)

---

## 🙌 Contributions

This app is part of a personal project.  
Issues and suggestions are welcome!

---
