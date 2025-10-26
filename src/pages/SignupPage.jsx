import React, { useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { auth, db } from "../firebase";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import "./Auth.css";
import "../pages/Home.css";

export default function SignupPage() {
  const navigate = useNavigate();
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleSignup = async (e) => {
    e.preventDefault();
    setError(null);
    setLoading(true);

    const formData = new FormData(e.currentTarget);
    const name = formData.get("name");
    const email = formData.get("email");
    const password = formData.get("password");
    const phone = formData.get("phone");
    const canReceiveCalls = formData.get("canReceiveCalls") === "on";

    if (!canReceiveCalls) {
      setError("You must agree to receive calls for verification to register.");
      setLoading(false);
      return;
    }

    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // Add all default fields including avatarUrl
      await setDoc(doc(db, "users", user.uid), {
        name: name,
        email: email,
        phone: phone,
        canReceiveCalls: canReceiveCalls,
        status: "pending",
        totalRatingScore: 0,
        numberOfRatings: 0,
        questsCompleted: 0,
        questsPosted: 0,
        questsGivenCompleted: 0,
        avatarUrl: null, // Default avatar is null
        unlockedAchievements: [],
      });

      navigate("/pending-approval");

    } catch (err) {
      console.error(err);
      if (err.code === 'auth/email-already-in-use') { setError("This email address is already registered. Please log in."); }
      else if (err.code === 'auth/weak-password') { setError("Password should be at least 6 characters long."); }
      else { setError("Failed to create account. Please try again."); }
      setLoading(false);
    }
  };

  return (
    <div className="auth-form-container">
      <Link to="/" className="auth-logo">
        <span className="brand-badge">B</span>
        <span className="brand-text">Barangay Quest</span>
      </Link>
      <h1>Create Account</h1>
      <form onSubmit={handleSignup} className="auth-form">
        <div className="auth-field"> <label htmlFor="name">Full Name</label> <input type="text" id="name" name="name" required /> </div>
        <div className="auth-field"> <label htmlFor="email">Email address</label> <input type="email" id="email" name="email" required /> </div>
        <div className="auth-field"> <label htmlFor="phone">Phone Number (e.g., 0917...)</label> <input type="tel" id="phone" name="phone" required /> </div>
        <div className="auth-field"> <label htmlFor="password">Password (min. 6 characters)</label> <input type="password" id="password" name="password" minLength="6" required /> </div>
        <div className="auth-options" style={{justifyContent: "flex-start", gap: "10px"}}>
          <input type="checkbox" name="canReceiveCalls" id="canReceiveCalls" style={{width: "auto"}} required />
          <label htmlFor="canReceiveCalls" style={{color: "var(--muted)", fontWeight: "normal"}}> I am willing to receive calls for verification. </label>
        </div>
        {error && ( <p style={{ color: "#ff8a8a", margin: 0 }}> {error.replace('Firebase: ', '')} </p> )}
        <button type="submit" className="btn btn-accent btn-auth" disabled={loading}> {loading ? "Creating..." : "Create Account"} </button>
      </form>
      <p className="auth-footer"> Already have an account?{" "} <Link to="/login" className="auth-link">Sign in</Link> </p>
    </div>
  );
}