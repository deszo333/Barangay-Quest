import React, { useState, useEffect } from 'react';
import { Link, useOutletContext } from 'react-router-dom';
import { db } from '../firebase'; // Import db
// Import doc and getDoc to fetch user data
import { collection, addDoc, serverTimestamp, query, where, getDocs, limit, doc, getDoc } from 'firebase/firestore';
import '../pages/FindJobs.css'; // Import relevant CSS for card styles
// achievements css removed

// Helper to get user context
function useUser() {
  return useOutletContext();
}

// --- formatPrice helper ---
function formatPrice(type, amount) {
  const num = Number(amount).toFixed(2);
  if (type === 'Hourly Rate') { return `₱${num} / hour`; }
  // Use span for consistent styling potential
  return `₱${num} <span>(Fixed)</span>`;
}
// --- formatTime helper ---
function formatTime(timestamp) {
  if (!timestamp) return "Just now";
  const seconds = Math.floor((new Date() - timestamp.toDate()) / 1000);
  let interval = seconds / 86400; // days
  if (interval > 1) return Math.floor(interval) + " days ago";
  interval = seconds / 3600; // hours
  if (interval > 1) return Math.floor(interval) + " hours ago";
    interval = seconds / 60; // minutes
  if (interval > 1) return Math.floor(interval) + " minutes ago";
  return "Just now";
}

// --- Badge Definitions Removed ---

const QuestCard = ({ quest }) => {
  const { user: loggedInUser } = useUser();
  const [loading, setLoading] = useState(false);
  const [applied, setApplied] = useState(false);
  const [error, setError] = useState(null);
  const [giverData, setGiverData] = useState(null); // State to hold the full data of the quest giver

  const {
    id, title, location, workType, budgetType, budgetAmount,
    imageUrl, createdAt, questGiverName, questGiverId
  } = quest;

  const isOwnQuest = loggedInUser?.uid === questGiverId;

  // Effect to check if applied
  useEffect(() => {
    setError(null);
    setApplied(false);

    const checkIfApplied = async () => {
      if (!loggedInUser || isOwnQuest) return;

      const appsRef = collection(db, "applications");
      const q = query(
        appsRef,
        where("questId", "==", id),
        where("applicantId", "==", loggedInUser.uid),
        limit(1)
      );

      try {
        const querySnapshot = await getDocs(q);
        if (!querySnapshot.empty) {
          setApplied(true);
        }
      } catch (err) {
        console.error("Error checking application status:", err);
      }
    };
    checkIfApplied();
  }, [loggedInUser, id, isOwnQuest]);

  // Effect to fetch Quest Giver's data (for rating)
  useEffect(() => {
    const fetchGiverData = async () => {
      if (!questGiverId) return;
      setGiverData(null); 
      try {
        const giverDocRef = doc(db, "users", questGiverId);
        const giverDocSnap = await getDoc(giverDocRef);
        if (giverDocSnap.exists()) {
          setGiverData(giverDocSnap.data());
        } else {
             console.warn(`Quest giver profile not found for ID: ${questGiverId}`);
        }
      } catch (err) {
        console.error("Error fetching giver data:", err);
      }
    };
    fetchGiverData();
  }, [questGiverId]);

  // Handle Apply
  const handleApply = async () => {
    setError(null);
    if (!loggedInUser) { setError("Please log in to apply."); return; }
    if (isOwnQuest) { setError("You cannot apply to your own quest."); return; }
    if (applied) return; 

    setLoading(true);

    try {
      await addDoc(collection(db, "applications"), {
        questId: id,
        questTitle: title,
        questGiverId: questGiverId,
        applicantId: loggedInUser.uid,
        applicantName: loggedInUser.name,
        status: "pending",
        appliedAt: serverTimestamp()
      });
      setApplied(true);
    } catch (err) {
      console.error("Error applying:", err);
      setError("Failed to apply. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const priceText = formatPrice(budgetType, budgetAmount);
  const timeText = formatTime(createdAt);
  const locationText = workType === 'Online' ? 'Online' : (location?.address || 'In Person');

  // Calculate average rating score from the fetched giverData
  const avgRating = giverData && giverData.numberOfRatings > 0
    ? (giverData.totalRatingScore / giverData.numberOfRatings).toFixed(1)
    : 'N/A'; 
  const ratingCount = giverData?.numberOfRatings || 0;
  // const giverBadges = getUserBadges(giverData); // Removed

  return (
    <div className="quest-card">
      <div className="card-header">
        <div className="card-header-text">
          <Link to={`/quest/${id}`} className="card-title">{title}</Link>
          <span className="card-location">{locationText}</span>
        </div>
        <img
          src={imageUrl || `https://ui-avatars.com/api/?name=${title.charAt(0)}&background=random`}
          alt={title}
          className="card-image"
        />
      </div>

      <div className="card-meta">
        <span>⭐ {avgRating}</span>
        <span style={{marginLeft: '-5px'}}>({ratingCount})</span>
        <span>•</span>
        <span>{timeText}</span>
        <span>•</span>
        <span>by
            <Link to={`/profile/${questGiverId}`} style={{fontWeight: 600, textDecoration: 'underline', marginLeft: '4px'}}>
                {questGiverName}
            </Link>
            {/* Badge map removed */}
        </span>
      </div>

      <div className="card-footer">
        <div
          className="card-price"
          dangerouslySetInnerHTML={{ __html: priceText }}
        />
        <div className="card-actions">
          <button
            className="btn btn-accent"
            onClick={handleApply}
            disabled={loading || applied || isOwnQuest}
          >
            {loading ? "Applying..." : (applied ? "Applied" : (isOwnQuest ? "Your Quest" : "Apply"))}
          </button>
        </div>
      </div>
      {error && <p style={{ color: "#ff8a8a", fontSize: '0.8rem', marginTop: '0.5rem', textAlign: 'right' }}>{error}</p>}
    </div>
  );
};

export default QuestCard;