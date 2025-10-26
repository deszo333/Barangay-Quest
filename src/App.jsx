import React, { useState } from "react";
import { Routes, Route, Outlet } from "react-router-dom";
import Navbar from "./components/Navbar.jsx";
import Home from "./pages/Home.jsx";
import LoginPage from "./pages/LoginPage.jsx";
import SignupPage from "./pages/SignupPage.jsx";

// You can create placeholder pages for these
const FindJobs = () => <div className="bq-container" style={{padding: "20px"}}><h2>Find Jobs Page</h2><p>Coming soon...</p></div>;
const PostJob = () => <div className="bq-container" style={{padding: "20px"}}><h2>Post a Job Page</h2><p>Coming soon...</p></div>;
const Leaderboard = () => <div className="bq-container" style={{padding: "20px"}}><h2>Leaderboard Page</h2><p>Coming soon...</p></div>;

export default function App() {
  const [user, setUser] = useState(null); // This is our global user state

  return (
    <div className="app-root">
      <Routes>
        <Route 
          path="/" 
          element={<Layout user={user} setUser={setUser} />}
        >
          {/* Outlet renders these child routes */}
          <Route index element={<Home />} />
          <Route path="login" element={<LoginPage />} />
          <Route path="signup" element={<SignupPage />} />
          <Route path="find-jobs" element={<FindJobs />} />
          <Route path="post-job" element={<PostJob />} />
          <Route path="leaderboard" element={<Leaderboard />} />

          {/* <Route path="*" element={<NotFound />} /> */}
        </Route>
      </Routes>
    </div>
  );
}

// Layout component renders the common Navbar and Footer
function Layout({ user, setUser }) {
  const handleLogout = () => {
    setUser(null);
  };

  return (
    <>
      <Navbar 
        user={user} 
        onLogoutClick={handleLogout} 
      />
      
      {/* Outlet renders the active child route (Home, LoginPage, etc.) */}
      <Outlet context={{ user, setUser }} />

      <Footer />
    </>
  );
}


function Footer() {
  return (
    <footer className="bq-footer" style={{marginTop: "40px"}}>
      <div className="bq-container footer-top">
        <a href="#" className="brand brand-footer">
          <span className="brand-badge">B</span>
          <span className="brand-text">Barangay Quest</span>
        </a>
        <div className="footer-links">
          <a href="#">About Us</a>
          <a href="#">Contact</a>
          <a href="#">Privacy</a>
        </div>
        <div className="socials">
          <a aria-label="Facebook" href="#" className="soc fb">f</a>
          <a aria-label="Twitter/X" href="#" className="soc tw">t</a>
          <a aria-label="Instagram" href="#" className="soc ig">i</a>
        </div>
      </div>
      <div className="footer-bottom">
        © {new Date().getFullYear()} Barangay Quest
      </div>
    </footer>
  );
}