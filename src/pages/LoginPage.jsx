import React from "react";
import { useOutletContext, Link, useNavigate } from "react-router-dom";
import "./Auth.css"; // Import the new CSS
import "../pages/Home.css"; // We still need this for the button styles

export default function LoginPage() {
  const { setUser } = useOutletContext();
  const navigate = useNavigate();

  const handleLogin = (e) => {
    e.preventDefault();
    setUser({ name: "Barangay Member" });
    navigate("/"); 
  };

  return (
    // REMOVED the .auth-layout and .auth-image divs
    // This container is now the root element
    <div className="auth-form-container">
      <Link to="/" className="auth-logo">
        <span className="brand-badge">B</span>
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

        <button type="submit" className="btn btn-accent btn-auth">
          Sign In
        </button>
      </form>

      <p className="auth-footer">
        Don't have an account?{" "}
        <Link to="/signup" className="auth-link">Sign up</Link>
      </p>
    </div>
  );
}