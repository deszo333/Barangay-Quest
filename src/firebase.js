import { initializeApp } from "firebase/app";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

// --- PASTE YOUR FIREBASE CONFIG OBJECT HERE ---
const firebaseConfig = {
  apiKey: "AIzaSyDsEt9CpNntc0aZ4CSAdu5jPrYNq45KGEg",
  authDomain: "barangay-quest.firebaseapp.com",
  projectId: "barangay-quest",
  storageBucket: "barangay-quest.firebasestorage.app",
  messagingSenderId: "335762528717",
  appId: "1:335762528717:web:dfd6d5cbdf8cbddacf4c84",
  measurementId: "G-TD1G8FQRKH"
};
// --- END OF YOUR CONFIG ---

// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Export the services your app will need
export const auth = getAuth(app);
export const db = getFirestore(app);
export default app;