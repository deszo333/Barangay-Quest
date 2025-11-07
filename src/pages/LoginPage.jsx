import React, { useState } from "react"; // Import useState
import { Link, useNavigate } from "react-router-dom";

// Firebase Imports
import { auth } from "../firebase";
import { signInWithEmailAndPassword } from "firebase/auth";

// CSS Imports
import "./Auth.css";
import "../pages/Home.css";

export default function LoginPage() {
  const navigate = useNavigate();
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false); // Loading state for button

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(null);
    setLoading(true); // Disable button

    const formData = new FormData(e.currentTarget);
    const email = formData.get("email");
    const password = formData.get("password");

    try {
      // 1. Sign in the user with Firebase Auth
      await signInWithEmailAndPassword(auth, email, password);

      // 2. Success! Navigate to home.
      // The listener in App.jsx will do the rest.
      navigate("/");

    } catch (err) {
      console.error(err);
      setError(err.message);
      setLoading(false); // Re-enable button
    }
  };

  return (
    <div className="auth-form-container">
      <Link to="/" className="auth-logo">
        <span className="brand-text">Barangay Quest</span>
      </Link>

      <h1>Sign In</h1>

      <form onSubmit={handleLogin} className="auth-form">
        <div className="auth-field">
          <label htmlFor="email">Email address</label>
          <input type="email" id="email" name="email" required />
        </div>

        <div className="auth-field">
          <label htmlFor="password">Password</label>
          <input type="password" id="password" name="password" required />
        </div>

        <div className="auth-options">
          <label>
            <input type="checkbox" name="remember" />
            Remember me
          </label>
          <Link to="/forgot-password" className="auth-link">Forgot password?</Link>
        </div>

        {/* Show error message if one exists */}
        {error && (
          <p style={{ color: "#ff8a8a", margin: "-8px 0 0" }}>
            {error.replace('Firebase: ', '')}
          </p>
        )}

        <button type="submit" className="btn btn-accent btn-auth" disabled={loading}>
          {loading ? "Signing In..." : "Sign In"}
        </button>
      </form>

      <p className="auth-footer">
        Don't have an account?{" "}
        <Link to="/signup" className="auth-link">Sign up</Link>
      </p>
    </div>
  );
}