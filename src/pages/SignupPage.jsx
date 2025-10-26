import React from "react";
import { useOutletContext, Link, useNavigate } from "react-router-dom";
import "./Auth.css"; // Import the new CSS
import "../pages/Home.css"; // Import button styles

export default function SignupPage() {
  const { setUser } = useOutletContext();
  const navigate = useNavigate();

  const handleSignup = (e) => {
    e.preventDefault();
    setUser({ name: "New Member" }); 
    navigate("/");
  };

  return (
    // REMOVED the .auth-layout and .auth-image divs
    <div className="auth-form-container">
      <Link to="/" className="auth-logo">
        <span className="brand-badge">B</span>
        <span className="brand-text">Barangay Quest</span>
      </Link>

      <h1>Create Account</h1>

      <form onSubmit={handleSignup} className="auth-form">
        <div className="auth-field">
          <label htmlFor="name">Full Name</label>
          <input type="text" id="name" name="name" required />
        </div>
        
        <div className="auth-field">
          <label htmlFor="email">Email address</label>
          <input type="email" id="email" name="email" required />
        </div>

        <div className="auth-field">
          <label htmlFor="password">Password</label>
          <input type="password" id="password" name="password" required />
        </div>

        <button type="submit" className="btn btn-accent btn-auth">
          Create Account
        </button>
      </form>

      <p className="auth-footer">
        Already have an account?{" "}
        <Link to="/login" className="auth-link">Sign in</Link>
      </p>
    </div>
  );
}