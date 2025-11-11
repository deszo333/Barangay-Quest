import React, { useState, useEffect } from "react";
import { Link, useNavigate } from "react-router-dom";
import { auth, db } from "../firebase";
import { createUserWithEmailAndPassword } from "firebase/auth";
import { doc, setDoc } from "firebase/firestore";
import "./Auth.css"; // We are using the full file
import "../pages/Home.css"; // For button styles

// Helper function to check password strength
const getPasswordStrength = (password) => {
  let score = 0;
  if (password.length > 8) score++;
  if (/[A-Z]/.test(password)) score++; // Uppercase
  if (/[a-z]/.test(password)) score++; // Lowercase
  if (/[0-9]/.test(password)) score++; // Numbers
  if (/[^A-Za-z0-9]/.test(password)) score++; // Symbols

  if (score <= 2) return { label: "Weak", color: "#f87171" }; // red
  if (score <= 3) return { label: "Medium", color: "#facc15" }; // yellow
  return { label: "Strong", color: "#4ade80" }; // green
};

export default function SignupPage() {
  const navigate = useNavigate();

  // --- Form Data State ---
  const [formData, setFormData] = useState({
    firstName: "",
    middleName: "",
    lastName: "",
    email: "",
    phone: "",
    city: "Manila",
    password: "",
    confirmPassword: "",
  });

  const [canReceiveCalls, setCanReceiveCalls] = useState(false);
  
  // --- UI/UX State ---
  const [showPassword, setShowPassword] = useState(false);
  const [passwordStrength, setPasswordStrength] = useState({ label: "", color: "transparent" });
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  // --- Handlers ---
  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handlePasswordChange = (e) => {
    const newPassword = e.target.value;
    setFormData(prev => ({ ...prev, password: newPassword }));
    if (newPassword.length > 0) {
      setPasswordStrength(getPasswordStrength(newPassword));
    } else {
      setPasswordStrength({ label: "", color: "transparent" });
    }
  };

  // Main signup logic
  const handleSignup = async (e) => {
    e.preventDefault();
    setError(null);

    // --- 1. Client-Side Validation ---
    if (formData.password !== formData.confirmPassword) {
      setError("Passwords do not match.");
      return;
    }
    if (!canReceiveCalls) {
      setError("You must agree to receive calls for verification to register.");
      return;
    }
    if (passwordStrength.label === "Weak") {
      setError("Password is too weak. Please add numbers, symbols, or uppercase letters.");
      return;
    }
    
    setLoading(true);

    const { firstName, middleName, lastName, email, phone, city, password } = formData;
    const name = `${firstName.trim()} ${middleName.trim()} ${lastName.trim()}`.replace(/\s+/g, ' ');

    try {
      const userCredential = await createUserWithEmailAndPassword(auth, email, password);
      const user = userCredential.user;

      // --- 2. Create User Document in Firestore ---
      await setDoc(doc(db, "users", user.uid), {
        name: name, 
        firstName: firstName.trim(),
        lastName: lastName.trim(),
        middleName: middleName.trim(),
        email: email,
        phone: phone,
        city: city.trim(),
        canReceiveCalls: canReceiveCalls,
        status: "pending",
        
        walletBalance: 5000, 
        
        // Default stats
        totalRatingScore: 0,
        numberOfRatings: 0,
        questsCompleted: 0,
        questsPosted: 0,
        questsGivenCompleted: 0,
        avatarUrl: null,
        // unlockedAchievements: [], // Removed
      });

      // --- 3. Redirect ---
      navigate("/pending-approval");

    } catch (err) {
      console.error(err);
      if (err.code === 'auth/email-already-in-use') {
        setError("This email address is already registered. Please log in.");
      } else {
        setError("Failed to create account. Please try again.");
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="auth-form-container" style={{ width: "min(500px, 90vw)" }}>
      <Link to="/" className="auth-logo">
        <span className="brand-text">Barangay Quest</span>
      </Link>
      <h1>Create Account</h1>
      
      <form onSubmit={handleSignup} className="auth-form">
        
        {/* --- Name Fields (Stacked) --- */}
        <div className="auth-field">
          <label htmlFor="firstName">First Name</label>
          <input type="text" id="firstName" name="firstName" value={formData.firstName} onChange={handleChange} required />
        </div>
        <div className="auth-field">
          <label htmlFor="middleName">Middle Name (Optional)</label>
          <input type="text" id="middleName" name="middleName" value={formData.middleName} onChange={handleChange} />
        </div>
        <div className="auth-field">
          <label htmlFor="lastName">Last Name</label>
          <input type="text" id="lastName" name="lastName" value={formData.lastName} onChange={handleChange} required />
        </div>

        {/* --- Email & Phone (Stacked) --- */}
        <div className="auth-field">
          <label htmlFor="email">Email address</label>
          <input type="email" id="email" name="email" value={formData.email} onChange={handleChange} required />
        </div>
        
        <div className="auth-field">
          <label htmlFor="phone">Phone Number</label>
          <input
            type="tel"
            id="phone"
            name="phone"
            placeholder="e.g., 09171234567"
            value={formData.phone}
            onChange={handleChange}
            required
            pattern="^09\d{9}$"
            maxLength="11"
            title="Phone number must be 11 digits starting with 09 (e.g., 09171234567)"
          />
        </div>

        {/* === START OF PASSWORD GROUP === */}
        <div className="password-group">
          {/* --- Password Fields (Grid) --- */}
          <div className="form-grid-2">
            <div className="auth-field">
              <label htmlFor="password">Password</label>
              <input
                type={showPassword ? "text" : "password"}
                id="password"
                name="password"
                value={formData.password}
                onChange={handlePasswordChange}
                minLength="6"
                required
              />
            </div>
            <div className="auth-field">
              <label htmlFor="confirmPassword">Confirm Password</label>
              <input
                type={showPassword ? "text" : "password"}
                id="confirmPassword"
                name="confirmPassword"
                value={formData.confirmPassword}
                onChange={handleChange}
                required
              />
            </div>
          </div>

          {/* --- Password Strength Indicator --- */}
          <div className="password-strength-bar">
            <div
              className="password-strength-fill"
              style={{
                width: passwordStrength.label === "Weak" ? "33%" : passwordStrength.label === "Medium" ? "66%" : "100%",
                backgroundColor: passwordStrength.color,
              }}
            ></div>
          </div>
          <span className="password-strength-label" style={{ color: passwordStrength.color }}>
            {passwordStrength.label}
          </span>
          
          {/* --- "Show Password" Toggle --- */}
          <div className="auth-options password-toggle">
            <label>
              <input
                type="checkbox"
                id="showPassword"
                checked={showPassword}
                onChange={() => setShowPassword(!showPassword)}
              />
              Show Password
            </label>
          </div>

          {/* --- "Receive Calls" Toggle --- */}
          <div className="auth-options call-toggle">
            <label>
              <input
                type="checkbox"
                name="canReceiveCalls"
                id="canReceiveCalls"
                checked={canReceiveCalls}
                onChange={(e) => setCanReceiveCalls(e.target.checked)}
                required
              />
              I am willing to receive calls for verification.
            </label>
          </div>
        </div>
        {/* === END OF PASSWORD GROUP === */}

        {/* Error Message */}
        {error && (
          <p style={{ color: "#ff8a8a", margin: "10px 0 0", textAlign: "center" }}>
            {error}
          </p>
        )}

        {/* Submit Button */}
        <button type="submit" className="btn btn-accent btn-auth" disabled={loading} style={{ marginTop: "1rem" }}>
          {loading ? "Creating Account..." : "Create Account"}
        </button>
      </form>

      <p className="auth-footer">
        Already have an account?{" "}
        <Link to="/login" className="auth-link">Sign in</Link>
      </p>
    </div>
  );
}