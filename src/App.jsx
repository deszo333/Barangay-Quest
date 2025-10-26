import React, { useState, useEffect } from "react";
import { Routes, Route, Outlet, Navigate, useLocation } from "react-router-dom";
import { auth, db } from "./firebase";
import { onAuthStateChanged } from "firebase/auth";
import { doc, getDoc } from "firebase/firestore";

// Components & Pages
import Navbar from "./components/Navbar.jsx";
import ApprovedRoute from "./components/ApprovedRoute.jsx";
import PendingRoute from "./components/PendingRoute.jsx";
import AdminRoute from "./components/AdminRoute.jsx";
import Home from "./pages/Home.jsx";
import LoginPage from "./pages/LoginPage.jsx";
import SignupPage from "./pages/SignupPage.jsx";
import PendingPage from "./pages/PendingPage.jsx";
import AdminDashboard from "./pages/AdminDashboard.jsx";
import PostJob from "./pages/PostJob.jsx";
import FindJobs from "./pages/FindJobs.jsx";
import QuestDetailPage from "./pages/QuestDetailPage.jsx";
import MyApplications from "./pages/MyApplications.jsx";
import MyQuests from "./pages/MyQuests.jsx";
import UserProfilePage from "./pages/UserProfilePage.jsx";
import AchievementsPage from "./pages/AchievementsPage.jsx";
import ProfileSettingsPage from "./pages/ProfileSettingsPage.jsx";

// Main App Component
export default function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        const userDocRef = doc(db, "users", firebaseUser.uid);
        const userDoc = await getDoc(userDocRef);
        if (userDoc.exists()) { setUser({ uid: firebaseUser.uid, email: firebaseUser.email, ...userDoc.data() }); }
        else { setUser({ uid: firebaseUser.uid, email: firebaseUser.email, name: "User", status: "pending", unlockedAchievements: [], questsCompleted: 0, questsPosted: 0, questsGivenCompleted: 0, totalRatingScore: 0, numberOfRatings: 0, avatarUrl: null }); }
      } else { setUser(null); }
      setLoading(false);
    });
    return () => unsubscribe();
  }, []);

  if (loading) { return <div className="bq-container" style={{padding: "40px", textAlign: "center"}}>Loading...</div>; }

  return (
    <div className="app-root">
      <Routes>
        <Route path="/" element={<Layout user={user} setUser={setUser} />} >
          {/* Public */}
          <Route index element={<Home />} />
          <Route path="login" element={<LoginPage />} />
          <Route path="signup" element={<SignupPage />} />

          {/* Approved */}
          <Route element={<ApprovedRoute user={user} />}>
            <Route path="find-jobs" element={<FindJobs />} />
            <Route path="post-job" element={<PostJob />} />
            <Route path="quest/:id" element={<QuestDetailPage />} />
            <Route path="my-applications" element={<MyApplications />} />
            <Route path="my-quests" element={<MyQuests />} />
            <Route path="profile/:userId" element={<UserProfilePage />} />
            <Route path="achievements" element={<AchievementsPage />} />
            <Route path="settings" element={<ProfileSettingsPage />} />
          </Route>

          {/* Pending */}
          <Route element={<PendingRoute user={user} />}>
            <Route path="pending-approval" element={<PendingPage />} />
          </Route>

          {/* Admin */}
          <Route element={<AdminRoute user={user} />}>
            <Route path="admin" element={<AdminDashboard />} />
          </Route>

        </Route>
      </Routes>
    </div>
  );
}

// Layout component
function Layout({ user, setUser }) {
  const handleLogout = () => { auth.signOut(); };
  const location = useLocation();
  const authRoutes = ['/login', '/signup'];
  if (user && authRoutes.includes(location.pathname)) { return <Navigate to="/" replace />; }
  return (
    <>
      <Navbar user={user} onLogoutClick={handleLogout} />
      {/* Wrap Outlet in main for sticky footer */}
      <main className="main-content-area">
        <Outlet context={{ user, setUser }} />
      </main>
      <Footer />
    </>
   );
}

// Footer component
function Footer() {
  return (
    <footer className="bq-footer">
      <div className="bq-container footer-top">
        <a href="#" className="brand brand-footer"> <span className="brand-badge">B</span> <span className="brand-text">Barangay Quest</span> </a>
        <div className="footer-links"> <a href="#">About Us</a> <a href="#">Contact</a> <a href="#">Privacy</a> </div>
        <div className="socials"> <a aria-label="Facebook" href="#" className="soc fb">f</a> <a aria-label="Twitter/X" href="#" className="soc tw">t</a> <a aria-label="Instagram" href="#" className="soc ig">i</a> </div>
      </div>
      <div className="footer-bottom"> © {new Date().getFullYear()} Barangay Quest </div>
    </footer>
  );
}