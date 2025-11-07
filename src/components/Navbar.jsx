import { NavLink, Link } from "react-router-dom";
import "./Navbar.css"; // Use the restored Navbar.css
// Import badge style (this link can be removed if AchievementsPage is deleted)
import '../pages/AchievementsPage.css';

// --- Badge logic completely removed ---

export default function Navbar({ user, onLogoutClick }) {
    // const badges = getUserBadges(user); // Removed

  return (
    <header className="navbar">
      <div className="brand">
        <Link to="/" className="brand-link">Barangay <b>Quest</b></Link>
      </div>

      <nav className="nav-center" aria-label="Main">
        {/* Links always visible */}
        <NavLink end to="/" className="nav-link">Home</NavLink>
        <NavLink to="/find-jobs" className="nav-link">Find Jobs</NavLink>

        {/* Links only visible to APPROVED users */}
        {user && user.status === 'approved' && (
          <>
            <NavLink to="/post-job" className="nav-link">Post a Job</NavLink>
            {/* Link to achievements removed */}
            {/* <NavLink to="/achievements" className="nav-link">Achievements</NavLink> */}
          </>
        )}
      </nav>

      <div className="auth">
        {user ? (
          // --- Logged In View ---
          <>
            <NavLink to="/my-applications" className="nav-link" style={{padding: '8px 10px', marginRight: '5px'}}>My Applications</NavLink>
            <NavLink to="/my-quests" className="nav-link" style={{padding: '8px 10px', marginRight: '10px'}}>My Quests</NavLink>
            <NavLink to="/settings" className="nav-link" style={{padding: '8px 10px', marginRight: '10px'}}>
              Profile
            </NavLink>

            {/* Display Wallet Balance */}
            <span style={{
              marginRight: "1rem", 
              fontWeight: "600", 
              color: 'var(--status-completed)', // Green color
              background: 'rgba(74, 222, 128, 0.1)',
              padding: '6px 12px',
              borderRadius: '8px',
              border: '1px solid rgba(74, 222, 128, 0.2)'
            }}>
              ₱{user.walletBalance?.toFixed(2) || '0.00'}
            </span>

            {/* Display User Name (Badges Removed) */}
            <span style={{marginRight: "12px", fontWeight: "600", color: 'var(--white)'}}>
              Hi, {user.name}!
              {/* Badge map removed */}
            </span>
            <button type="button" className="btn ghost" onClick={onLogoutClick}> Log Out </button>
          </>
        ) : (
          // --- Logged Out View ---
          <>
            <Link to="/login" className="btn ghost">Log In</Link>
            <Link to="/signup" className="btn solid">Sign Up</Link>
          </>
        )}
      </div>
    </header>
  );
}