import React, { useState, useEffect } from 'react';
import { Link, useOutletContext } from 'react-router-dom';
import { db } from '../firebase'; // Import db
// Import doc and getDoc to fetch user data
import { collection, addDoc, serverTimestamp, query, where, getDocs, limit, doc, getDoc } from 'firebase/firestore';
import '../pages/FindJobs.css'; // Import relevant CSS for card styles
import '../pages/AchievementsPage.css'; // Import badge style

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

// --- Badge Definitions (Copied from Navbar.jsx) ---
const ACHIEVEMENT_BADGES = {
    'seasoned_quester_2': '🌟', // Example: Show Seasoned Quester II badge
    'top_rated': '🏆',         // Example: Show Top Rated badge
    // Add more badge IDs and their corresponding icons here
};

// Helper function to get badge icons for a user
function getUserBadges(user) { // Pass the user DATA object, not the context hook result
    if (!user || !user.unlockedAchievements) return []; // Return empty array if no user or achievements
    return user.unlockedAchievements
        .filter(id => ACHIEVEMENT_BADGES[id]) // Check if we have a badge defined for this achievement ID
        .map(id => ({ id, icon: ACHIEVEMENT_BADGES[id] })); // Return objects with id and icon
}
// --- End Badge Definitions ---

const QuestCard = ({ quest }) => {
  const { user: loggedInUser } = useUser(); // Rename loggedInUser to avoid conflict
  const [loading, setLoading] = useState(false); // Loading state for apply button
  const [applied, setApplied] = useState(false); // Has the current logged-in user applied?
  const [error, setError] = useState(null); // Error messages related to applying
  const [giverData, setGiverData] = useState(null); // State to hold the full data of the quest giver

  // Destructure all necessary properties from the quest prop
  const {
    id, title, location, workType, budgetType, budgetAmount,
    imageUrl, createdAt, questGiverName, questGiverId
  } = quest;

  // Determine if the current logged-in user is the one who posted this quest
  const isOwnQuest = loggedInUser?.uid === questGiverId;

  // Effect to check if the current user has already applied to this specific quest
  useEffect(() => {
    setError(null); // Clear previous errors on load or when user/quest changes
    setApplied(false); // Reset applied status

    const checkIfApplied = async () => {
      // Don't proceed if user isn't logged in, or if it's their own quest
      if (!loggedInUser || isOwnQuest) return;

      const appsRef = collection(db, "applications");
      // Query for an application document linking this quest and the logged-in user
      const q = query(
        appsRef,
        where("questId", "==", id),
        where("applicantId", "==", loggedInUser.uid),
        limit(1) // Only need to find if one exists
      );

      try {
        const querySnapshot = await getDocs(q);
        // If the query is not empty, it means an application exists
        if (!querySnapshot.empty) {
          setApplied(true); // Set state to true
        }
      } catch (err) {
        console.error("Error checking application status:", err);
        // Log the error, but don't necessarily block the UI
      }
    };
    checkIfApplied();
  }, [loggedInUser, id, isOwnQuest]); // Rerun this effect if user, quest id, or ownership changes

  // Effect to fetch the Quest Giver's full data (including achievements for badges)
  useEffect(() => {
    const fetchGiverData = async () => {
      if (!questGiverId) return; // Need the ID to fetch
      setGiverData(null); // Reset previous data
      try {
        const giverDocRef = doc(db, "users", questGiverId);
        const giverDocSnap = await getDoc(giverDocRef);
        if (giverDocSnap.exists()) {
          setGiverData(giverDocSnap.data()); // Store all fetched giver data
        } else {
             console.warn(`Quest giver profile not found for ID: ${questGiverId}`);
             // Keep giverData as null if not found
        }
      } catch (err) {
        console.error("Error fetching giver data:", err);
        // Keep giverData as null on error
      }
    };
    fetchGiverData();
  }, [questGiverId]); // Rerun this effect if the quest giver ID changes

  // Function to handle clicking the "Apply" button
  const handleApply = async () => {
    setError(null); // Clear previous apply errors
    // Check various conditions before proceeding
    if (!loggedInUser) { setError("Please log in to apply."); return; }
    if (isOwnQuest) { setError("You cannot apply to your own quest."); return; }
    if (applied) return; // Prevent applying multiple times if already applied

    setLoading(true); // Set loading state for button feedback

    try {
      // Add a new document to the 'applications' collection in Firestore
      await addDoc(collection(db, "applications"), {
        questId: id,
        questTitle: title,
        questGiverId: questGiverId,
        applicantId: loggedInUser.uid,
        applicantName: loggedInUser.name, // Assumes user object (from context) has name
        status: "pending", // Initial status for a new application
        appliedAt: serverTimestamp() // Record the application time using server timestamp
      });
      setApplied(true); // Update state to reflect successful application
    } catch (err) {
      console.error("Error applying:", err);
      setError("Failed to apply. Please try again."); // Set user-facing error message
    } finally {
      setLoading(false); // Reset loading state regardless of success or failure
    }
  };

  // Prepare display strings based on quest data
  const priceText = formatPrice(budgetType, budgetAmount);
  const timeText = formatTime(createdAt);
  const locationText = workType === 'Online' ? 'Online' : (location?.address || 'In Person');

  // Calculate average rating score from the fetched giverData
  const avgRating = giverData && giverData.numberOfRatings > 0
    ? (giverData.totalRatingScore / giverData.numberOfRatings).toFixed(1) // Calculate if count > 0
    : 'N/A'; // Display 'N/A' if no ratings yet
  const ratingCount = giverData?.numberOfRatings || 0; // Get rating count or default to 0
  const giverBadges = getUserBadges(giverData); // Get badge icons based on giver's achievements

  // Render the Quest Card component
  return (
    <div className="quest-card">
      <div className="card-header">
        <div className="card-header-text">
          {/* Link title to the detailed quest page */}
          <Link to={`/quest/${id}`} className="card-title">{title}</Link>
          <span className="card-location">{locationText}</span>
        </div>
        {/* Display quest image or a generated avatar based on title */}
        <img
          src={imageUrl || `https://ui-avatars.com/api/?name=${title.charAt(0)}&background=random`}
          alt={title}
          className="card-image"
        />
      </div>

      <div className="card-meta">
        {/* Display Giver's Average Rating */}
        <span>⭐ {avgRating}</span>
        <span style={{marginLeft: '-5px'}}>({ratingCount})</span>
        <span>•</span>
        <span>{timeText}</span>
        <span>•</span>
        {/* Display Giver Name as a link to their profile, followed by badges */}
        <span>by
            <Link to={`/profile/${questGiverId}`} style={{fontWeight: 600, textDecoration: 'underline', marginLeft: '4px'}}>
                {questGiverName}
            </Link>
            {/* Map through the giver's badges and display each icon */}
            {giverBadges.map(badge => (
                <span key={badge.id} className="user-badge" title={badge.id.replace(/_/g, ' ')}> {/* Basic tooltip showing achievement ID */}
                     {badge.icon}
                </span>
            ))}
        </span>
      </div>

      <div className="card-footer">
        {/* Display formatted price */}
        <div
          className="card-price"
          dangerouslySetInnerHTML={{ __html: priceText }} // Allows rendering the span tag in price text
        />
        <div className="card-actions">
          {/* Save button (functionality not implemented yet) */}
          <button className="btn btn-secondary btn-save">Save</button>
          {/* Apply button with dynamic text and disabled state */}
          <button
            className="btn btn-accent"
            onClick={handleApply}
            // Disable if loading, already applied, or if it's the user's own quest
            disabled={loading || applied || isOwnQuest}
          >
            {loading ? "Applying..." : (applied ? "Applied" : (isOwnQuest ? "Your Quest" : "Apply"))}
          </button>
        </div>
      </div>
      {/* Display any error messages from the apply action */}
      {error && <p style={{ color: "#ff8a8a", fontSize: '0.8rem', marginTop: '0.5rem', textAlign: 'right' }}>{error}</p>}
    </div>
  );
};

export default QuestCard; // Export the component