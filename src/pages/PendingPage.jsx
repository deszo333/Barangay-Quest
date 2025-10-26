import React from 'react';
import { useOutletContext } from 'react-router-dom';
import { auth } from '../firebase';
import "./Auth.css"; // We can reuse the Auth CSS
import "../pages/Home.css"; // For button styles

// This helper component gets the 'user' object from the main layout
function useUser() {
  return useOutletContext();
}

export default function PendingPage() {
  const { user } = useUser(); // Get the current user

  // Prevent flicker if user data is still loading
  if (!user) {
    return null;
  }

  return (
    <div className="auth-form-container" style={{ textAlign: 'center' }}>
      <h1>Account Pending Approval</h1>
      <p style={{ color: 'var(--muted)', lineHeight: 1.6 }}>
        Welcome, {user?.name || 'User'}! Your account has been created
        but must be approved by a barangay administrator.
      </p>
      
      <p style={{ 
        color: 'var(--white)', 
        lineHeight: 1.6, 
        marginTop: '2rem',
        background: 'var(--card)',
        padding: '1rem',
        borderRadius: 'var(--radius)',
        border: '1px solid #20455b'
      }}>
        {/* THIS IS THE CORRECTED LINE */}
        Based on the number you provided ({user.phone || '...loading'}), 
        please expect a call or text from an admin for verification.
      </p>

      <button 
        onClick={() => auth.signOut()} 
        className="btn btn-secondary" 
        style={{marginTop: "2rem", background: "transparent"}}
      >
        Log Out
      </button>
    </div>
  );
}