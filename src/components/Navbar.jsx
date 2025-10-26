import { NavLink, Link } from "react-router-dom";
import "./Navbar.css"; // Use the restored Navbar.css
// Import badge style
import '../pages/AchievementsPage.css';

// Badge Definitions
const ACHIEVEMENT_BADGES = {
    'seasoned_quester_2': '🌟', 'top_rated': '🏆', 'quest_giver_2': ' M',
    'quest_initiator': '✍️', 'first_quest_completed': '👟',
};
// Helper function to get badge icons for a user
function getUserBadges(user) {
    if (!user || !user.unlockedAchievements) return [];
    return user.unlockedAchievements
        .filter(id => ACHIEVEMENT_BADGES[id])
        .map(id => ({ id, icon: ACHIEVEMENT_BADGES[id] }));
}

export default function Navbar({ user, onLogoutClick }) {
    const badges = getUserBadges(user); // Get badges for the logged-in user

  return (
    // Use the class defined in Navbar.css
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
            <NavLink to="/achievements" className="nav-link">Achievements</NavLink>
          </>
        )}
      </nav>

      <div className="auth">
        {user ? (
          // --- Logged In View ---
          <>
            {/* Links only visible when logged in */}
            <NavLink to="/my-applications" className="nav-link" style={{padding: '8px 10px', marginRight: '5px'}}>My Applications</NavLink>
            <NavLink to="/my-quests" className="nav-link" style={{padding: '8px 10px', marginRight: '10px'}}>My Quests</NavLink>
            <NavLink to="/settings" className="nav-link" style={{padding: '8px 10px', marginRight: '10px'}}>Settings</NavLink>

            {/* Display User Name with Badges */}
            <span style={{marginRight: "12px", fontWeight: "600", color: 'var(--white)'}}>
              Hi, {user.name}!
              {badges.map(badge => (
                  <span key={badge.id} className="user-badge" title={badge.id.replace(/_/g, ' ')}>
                      {badge.icon}
                  </span>
              ))}
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