import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { db } from '../firebase';
import { doc, getDoc, collection, query, where, orderBy, getDocs, documentId } from 'firebase/firestore';
import "./MyApplications.css"; // Reuse sidebar styles
import "./MyQuests.css"; // Reuse quest list styles

// Helper for date formatting
function formatDate(timestamp) {
  if (!timestamp) return "";
  const seconds = Math.floor((new Date() - timestamp.toDate()) / 1000);
  let interval = seconds / 86400; // Days
  if (interval > 1) return timestamp.toDate().toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
  interval = seconds / 3600; // Hours
  if (interval > 1) return Math.floor(interval) + "h ago";
   interval = seconds / 60; // Minutes
  if (interval > 1) return Math.floor(interval) + "m ago";
  return "Just now";
}
// Helper for price formatting
function formatPrice(type, amount) {
  const num = Number(amount).toFixed(2);
  if (type === 'Hourly Rate') { return `₱${num} / hr`; }
  return `₱${num} Fixed`;
}


export default function UserProfilePage() {
  const { userId } = useParams(); // Get user ID from URL
  const [profileUser, setProfileUser] = useState(null);
  const [postedQuests, setPostedQuests] = useState([]);
  const [completedQuests, setCompletedQuests] = useState([]); // Quests completed as applicant
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Effect to fetch user profile and their associated quests
  useEffect(() => {
    const fetchUserProfileAndQuests = async () => {
      if (!userId) return; // Exit if no userId is provided in the URL
      setLoading(true); setError(null); setPostedQuests([]); setCompletedQuests([]); // Reset states

      try {
        // --- 1. Fetch User Profile Document ---
        const userDocRef = doc(db, "users", userId);
        const userDocSnap = await getDoc(userDocRef);

        if (userDocSnap.exists()) {
          setProfileUser({ id: userDocSnap.id, ...userDocSnap.data() }); // Store user data

          // --- 2. Fetch Quests Posted BY this user ---
          const postedQuery = query(
            collection(db, "quests"),
            where("questGiverId", "==", userId), // Filter by giver ID
            orderBy("createdAt", "desc") // Order by creation date
            // limit(5) // Optionally limit the number shown
          );
          const postedSnapshot = await getDocs(postedQuery);
          const postedData = postedSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
          setPostedQuests(postedData);

          // --- 3. Fetch Quests Completed BY this user (as applicant) ---
          // First, find application documents where this user was the applicant and status is completed
          const completedAppsQuery = query(
            collection(db, "applications"),
            where("applicantId", "==", userId),
            where("status", "==", "completed")
            // orderBy("completedAt", "desc") // Requires completedAt field and maybe an index
          );
          const completedAppsSnapshot = await getDocs(completedAppsQuery);
          // Extract the quest IDs from these applications
          const completedQuestIds = completedAppsSnapshot.docs.map(doc => doc.data().questId);

          // If there are completed quest IDs, fetch the details of those quests
          // Note: Firestore 'in' query is limited to 10 IDs per query. For more, use multiple queries or adjust logic.
          if (completedQuestIds.length > 0) {
              const completedQuestsQuery = query(
                  collection(db, "quests"),
                  // Use documentId() to query based on document IDs
                  where(documentId(), "in", completedQuestIds.slice(0, 10)) // Fetch max 10 completed quest details
              );
              const completedQuestsSnapshot = await getDocs(completedQuestsQuery);
              const completedData = completedQuestsSnapshot.docs.map(doc => ({id: doc.id, ...doc.data() }));
              setCompletedQuests(completedData);
          } else {
              setCompletedQuests([]); // Set empty array if no completed quests found
          }

        } else {
          setError("User profile not found."); // Set error if user document doesn't exist
        }
      } catch (err) {
        console.error("Error fetching user profile/quests:", err);
         if (err.code === 'failed-precondition') { // Specific check for missing index error
             console.error("Firestore index missing for profile page:", err);
             console.log("Create required index via the link in the Firestore console.");
             setError("Database setup needed. Please check Firebase console.");
        } else {
            setError("Could not load user profile or quests."); // Generic error
        }
      } finally {
        setLoading(false); // Ensure loading is set to false after fetch attempt
      }
    };
    fetchUserProfileAndQuests(); // Call the fetch function
  }, [userId]); // Rerun effect if the userId from the URL changes

  // Display loading state
  if (loading) {
    return <div className="bq-container" style={{ padding: "2rem" }}>Loading profile...</div>;
  }

  // Display error state if fetching failed
  if (error) {
    return <div className="bq-container" style={{ padding: "2rem", color: '#ff8a8a' }}>{error}</div>;
  }

  // Display if user profile wasn't found (should be caught by error, but good fallback)
  if (!profileUser) {
    return <div className="bq-container" style={{ padding: "2rem" }}>User not found.</div>;
  }

  // Calculate user's average rating
  const avgRating = profileUser.numberOfRatings > 0
    ? (profileUser.totalRatingScore / profileUser.numberOfRatings).toFixed(1)
    : 'N/A'; // Display 'N/A' if no ratings

  // Determine the avatar source URL (uploaded or generated)
  const avatarSrc = profileUser.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(profileUser.name)}&background=random`;

  return (
    <div className="bq-container">
      {/* Reuse MyApplications layout structure */}
      <div className="my-applications-layout">
        {/* Left Sidebar showing user info */}
        <aside className="profile-sidebar">
          {/* Use determined avatar source */}
          <img src={avatarSrc} alt={profileUser.name} className="profile-avatar" />
          <h2>{profileUser.name}</h2>
          <p>{profileUser.email}</p>
          <div className="profile-stats">
             {/* Display Average Rating */}
             <div className="stat-item" style={{ gridColumn: 'span 2', textAlign: 'center' }}>
              <span className="stat-value">⭐ {avgRating}</span>
              <span className="stat-label">({profileUser.numberOfRatings || 0} Ratings)</span>
            </div>
             {/* Display Quests Posted Count */}
             <div className="stat-item">
              <span className="stat-value">{postedQuests.length}</span>
              <span className="stat-label">Quests Posted</span>
            </div>
             {/* Display Quests Completed Count */}
             <div className="stat-item">
              <span className="stat-value">{completedQuests.length}</span>
              <span className="stat-label">Quests Done</span>
            </div>
          </div>
        </aside>

        {/* Right Panel showing quest lists */}
        <main className="applications-panel"> {/* Reusing class name */}
          <h1>{profileUser.name}'s Profile</h1>

          {/* --- Section for Quests Posted --- */}
          <section style={{marginBottom: '2rem'}}>
            <h2>Quests Posted ({postedQuests.length})</h2>
            {postedQuests.length === 0 ? (
                <p>This user hasn't posted any quests yet.</p>
            ) : (
                <div className="quests-list"> {/* Reuse quests-list style */}
                    {postedQuests.map(quest => (
                        // Render each posted quest as a clickable link/card
                        <Link to={`/quest/${quest.id}`} key={quest.id} className="posted-quest-item" style={{display: 'block', textDecoration: 'none'}}>
                           <h3>{quest.title}</h3>
                           <p>{quest.location?.address || quest.workType} • {formatDate(quest.createdAt)}</p>
                           <p style={{marginTop: '0.5rem'}}>
                               <span style={{fontWeight: 600, color: 'var(--white)'}}>{formatPrice(quest.budgetType, quest.budgetAmount)}</span>
                               {' • '}
                               <span className={`app-status ${quest.status}`} style={{textTransform: 'capitalize'}}>{quest.status}</span>
                           </p>
                        </Link>
                    ))}
                </div>
            )}
          </section>

          {/* Separator */}
          <hr style={{borderColor: 'var(--card)', margin: '2rem 0'}}/>

          {/* --- Section for Quests Completed (as Quester) --- */}
           <section>
            <h2>Quests Completed ({completedQuests.length})</h2>
            {completedQuests.length === 0 ? (
                <p>This user hasn't completed any quests yet.</p>
            ) : (
                <div className="quests-list">
                    {completedQuests.map(quest => (
                        // Render each completed quest as a clickable link/card
                        <Link to={`/quest/${quest.id}`} key={quest.id} className="posted-quest-item" style={{display: 'block', textDecoration: 'none'}}>
                           <h3>{quest.title}</h3>
                            {/* TODO: Need completed date on application document, fetch quest giver name properly if needed */}
                            <p>Completed on: [Date needed] • Posted by: {quest.questGiverName || 'Unknown'}</p>
                           <p style={{marginTop: '0.5rem'}}>
                               <span style={{fontWeight: 600, color: 'var(--white)'}}>{formatPrice(quest.budgetType, quest.budgetAmount)}</span>
                               {/* Add link/button to view rating given/received later */}
                           </p>
                        </Link>
                    ))}
                </div>
            )}
          </section>

        </main>
      </div>
    </div>
  );
}