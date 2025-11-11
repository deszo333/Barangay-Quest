import React, { useState, useEffect } from 'react';
import { useParams, Link } from 'react-router-dom';
import { db } from '../firebase';
import { doc, getDoc, collection, query, where, orderBy, getDocs, documentId, limit } from 'firebase/firestore';
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

// --- ADD THIS COMPONENT ---
function StarRating({ rating }) {
  const stars = [];
  for (let i = 1; i <= 5; i++) {
    stars.push(
      <span key={i} style={{ color: i <= rating ? '#ffd166' : 'var(--muted)', fontSize: '1.2rem' }}>
        ★
      </span>
    );
  }
  return <div>{stars}</div>;
}

// --- ADD THIS COMPONENT ---
function ReviewCard({ review }) {
  return (
    <div className="posted-quest-item" style={{display: 'block', marginBottom: '1rem'}}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '0.5rem' }}>
        <StarRating rating={review.rating} />
        <span style={{ color: 'var(--muted)', fontSize: '0.9rem' }}>{formatDate(review.timestamp)}</span>
      </div>
      {review.reviewText && (
        <p style={{ color: 'var(--white)', fontStyle: 'italic', margin: '0 0 0.75rem' }}>
          "{review.reviewText}"
        </p>
      )}
      <p style={{ margin: 0, fontSize: '0.9rem', color: 'var(--muted)' }}>
        For Quest: <Link to={`/quest/${review.questId}`} style={{ color: 'var(--accent)', textDecoration: 'underline' }}>{review.questTitle}</Link>
      </p>
    </div>
  );
}


export default function UserProfilePage() {
  const { userId } = useParams(); // Get user ID from URL
  const [profileUser, setProfileUser] = useState(null);
  const [reviewsAsQuester, setReviewsAsQuester] = useState([]); // <-- NEW
  const [reviewsAsGiver, setReviewsAsGiver] = useState([]);     // <-- NEW
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Effect to fetch user profile and their reviews
  useEffect(() => {
    const fetchUserProfileAndReviews = async () => {
      if (!userId) return;
      setLoading(true); setError(null); setReviewsAsGiver([]); setReviewsAsQuester([]);

      try {
        // --- 1. Fetch User Profile Document ---
        const userDocRef = doc(db, "users", userId);
        const userDocSnap = await getDoc(userDocRef);

        if (userDocSnap.exists()) {
          setProfileUser({ id: userDocSnap.id, ...userDocSnap.data() }); // Store user data

          // --- 2. Fetch Reviews as Quester (Givers rated them) ---
          const asQuesterQuery = query(
            collection(db, "applications"),
            where("applicantId", "==", userId),
            where("giverRated", "==", true),
            orderBy("approvedAt", "desc"),
            limit(10)
          );
          const asQuesterSnapshot = await getDocs(asQuesterQuery);
          const questerReviews = asQuesterSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
              id: doc.id,
              rating: data.giverRating,
              reviewText: data.review,
              questTitle: data.questTitle,
              questId: data.questId,
              timestamp: data.approvedAt
            };
          });
          setReviewsAsQuester(questerReviews);

          // --- 3. Fetch Reviews as Giver (Questers rated them) ---
          const asGiverQuery = query(
            collection(db, "applications"),
            where("questGiverId", "==", userId),
            where("questerRated", "==", true),
            orderBy("appliedAt", "desc"),
            limit(10)
          );
          const asGiverSnapshot = await getDocs(asGiverQuery);
          const giverReviews = asGiverSnapshot.docs.map(doc => {
            const data = doc.data();
            return {
              id: doc.id,
              rating: data.questerRating,
              reviewText: data.questerReview,
              questTitle: data.questTitle,
              questId: data.questId,
              timestamp: data.appliedAt
            };
          });
          setReviewsAsGiver(giverReviews);
        } else {
          setError("User profile not found."); // Set error if user document doesn't exist
        }
      } catch (err) {
        console.error("Error fetching user profile/reviews:", err);
         if (err.code === 'failed-precondition') { // Specific check for missing index error
             console.error("Firestore index missing for profile page:", err);
             console.log("Create required index via the link in the Firestore console.");
             setError("Database setup needed. Please check Firebase console.");
        } else {
            setError("Could not load user profile or reviews."); // Generic error
        }
      } finally {
        setLoading(false); // Ensure loading is set to false after fetch attempt
      }
    };
    fetchUserProfileAndReviews(); // Call the fetch function
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
            {/* --- FIX: Read stats from profileUser --- */}
            <div className="stat-item">
              <span className="stat-value">{profileUser.questsPosted || 0}</span>
              <span className="stat-label">Quests Posted</span>
            </div>
            <div className="stat-item">
              <span className="stat-value">{profileUser.questsCompleted || 0}</span>
              <span className="stat-label">Quests Done</span>
            </div>
            {/* --- END FIX --- */}
          </div>
        </aside>

        {/* Right Panel showing quest lists */}
        <main className="applications-panel"> {/* Reusing class name */}
          <h1>{profileUser.name}'s Reviews</h1>

          {/* --- Section for Reviews as Quester --- */}
          <section style={{marginBottom: '2rem'}}>
            <h2>Reviews as Quester ({reviewsAsQuester.length})</h2>
            {reviewsAsQuester.length === 0 ? (
                <p>This user hasn't received any reviews as a quester yet.</p>
            ) : (
                <div className="reviews-list">
                    {reviewsAsQuester.map(review => (
                        <ReviewCard key={review.id} review={review} />
                    ))}
                </div>
            )}
          </section>

          {/* Separator */}
          <hr style={{borderColor: 'var(--card)', margin: '2rem 0'}}/>

          {/* --- Section for Reviews as Giver --- */}
          <section>
            <h2>Reviews as Giver ({reviewsAsGiver.length})</h2>
            {reviewsAsGiver.length === 0 ? (
                <p>This user hasn't received any reviews as a giver yet.</p>
            ) : (
                <div className="reviews-list">
                    {reviewsAsGiver.map(review => (
                        <ReviewCard key={review.id} review={review} />
                    ))}
                </div>
            )}
          </section>
          
          {/* --- OLD QUESTS COMPLETED SECTION IS NOW REMOVED --- */}

        </main>
      </div>
    </div>
  );
}