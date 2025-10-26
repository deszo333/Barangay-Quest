import { NavLink, Link } from "react-router-dom";
import "./Navbar.css";

// Accept 'user' and 'onLogoutClick' as props from App.jsx
export default function Navbar({ user, onLogoutClick }) {
  return (
    <header className="navbar">
      <div className="brand">
        <Link to="/" className="brand-link">Barangay <b>Quest</b></Link>
      </div>

      <nav className="nav-center" aria-label="Main">
        <NavLink end to="/" className="nav-link">Home</NavLink>
        <NavLink to="/find-jobs" className="nav-link">Find Jobs</NavLink>
        <NavLink to="/post-job" className="nav-link">Post a Job</NavLink>
        <NavLink to="/leaderboard" className="nav-link">Leaderboard</NavLink> {/* <-- This is the fix */}
      </nav>

      <div className="auth">
        {user ? (
          // If user exists, show greeting and Log Out
          <>
            <span style={{marginRight: "12px", fontWeight: "600"}}>
              Hi, {user.name}!
            </span>
            <button type="button" className="btn ghost" onClick={onLogoutClick}>
              Log Out
            </button>
          </>
        ) : (
          // If no user, show Log In and Sign Up
          <>
            <Link to="/login" className="btn ghost">
              Log In
            </Link>
            <Link to="/signup" className="btn solid">
              Sign Up
            </Link>
          </>
        )}
      </div>
    </header>
  );
}