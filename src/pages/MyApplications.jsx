import React, { useState, useEffect, useMemo } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import { db } from '../firebase';
// Import transaction and increment
import { collection, query, where, getDocs, orderBy, deleteDoc, doc, runTransaction, updateDoc, increment } from 'firebase/firestore';
import StarRatingInput from '../components/StarRatingInput';
import "./MyApplications.css";
import "../pages/Home.css";

// Helper hook to get user context
function useUser() { return useOutletContext(); }

// Helper function for date formatting
function formatDate(timestamp) {
  if (!timestamp) return "";
  return timestamp.toDate().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

// --- Application Item Component ---
function ApplicationItem({ application, onWithdraw, onRateGiver }) {
    const [showRatingInput, setShowRatingInput] = useState(false);
    const [rating, setRating] = useState(0);
    const [ratingLoading, setRatingLoading] = useState(false);
    const [giverName, setGiverName] = useState('Quest Giver'); // State for giver name

    // Fetch Giver Name for Rating Prompt
    useEffect(() => {
        const fetchGiverName = async () => {
            if (application.questGiverId) {
                try {
                    const giverRef = doc(db, "users", application.questGiverId);
                    const giverSnap = await getDoc(giverRef);
                    if (giverSnap.exists()) {
                        setGiverName(giverSnap.data().name);
                    }
                } catch (error) {
                    console.error("Error fetching giver name:", error)
                }
            }
        };

        if (application.status === 'completed' && !application.questerRated) {
            setShowRatingInput(true);
            fetchGiverName(); // Fetch name only when showing input
        } else {
            setShowRatingInput(false);
            setRating(0);
        }
    }, [application.status, application.questerRated, application.questGiverId]);

    // Submit rating function
    const submitRating = async () => {
        if (rating === 0 || !application.questGiverId || !application.id) return;
        setRatingLoading(true);
        await onRateGiver(application.questGiverId, rating, application.id);
        setRatingLoading(false);
    };

    return (
        <div className="application-item">
            {/* Placeholder logo using first letter of quest title */}
            <img src={`https://ui-avatars.com/api/?name=${application.questTitle?.charAt(0)}&background=random`} alt="" className="app-logo" />

            <div className="app-details">
                <h3>{application.questTitle || 'Quest Title Missing'}</h3>
                <p>Applied {formatDate(application.appliedAt)}</p>
                <p style={{ marginTop: '0.5rem' }}>
                    <span className={`app-status ${application.status}`}>{application.status}</span>
                </p>
            </div>

            <div className="app-actions">
                <Link to={`/quest/${application.questId}`} className="btn btn-accent">View Quest</Link>
                {/* Only allow withdraw if application status is pending */}
                {application.status === 'pending' && (
                    <button
                        className="btn btn-secondary btn-save" // Reusing style
                        onClick={() => onWithdraw(application.id)}
                    >
                        Withdraw
                    </button>
                )}
            </div>

            {/* --- Rating Section for Giver --- */}
            {showRatingInput && (
                <div className="app-rating-section">
                    <h4>Rate {giverName}</h4>
                    <StarRatingInput rating={rating} setRating={setRating} />
                    <button
                        className="btn btn-accent"
                        style={{ marginTop: '1rem' }}
                        onClick={submitRating}
                        disabled={rating === 0 || ratingLoading}
                    >
                        {ratingLoading ? "Submitting..." : "Submit Rating"}
                    </button>
                </div>
            )}
        </div>
    );
}


// --- MAIN PAGE COMPONENT ---
export default function MyApplications() {
  const { user } = useUser(); // Get logged-in user data from context
  const [applications, setApplications] = useState([]); // State for fetched applications
  const [loading, setLoading] = useState(true); // Loading state
  const [filter, setFilter] = useState('All'); // Current active tab filter
  const [error, setError] = useState(null); // Error message state
  const [actionMessage, setActionMessage] = useState(""); // Feedback message state

  // Effect to fetch user's applications from Firestore
  const fetchApplications = async () => {
      if (!user) return; // Don't run if user isn't loaded
      try {
        setLoading(true); setError(null); setActionMessage(""); // Reset states
        const appsCollection = collection(db, "applications");
        
        // --- THIS IS THE FIX for "Unnecessary" ---
        // Query applications where applicantId matches AND status is one of the valid ones
        const q = query(
          appsCollection,
          where("applicantId", "==", user.uid),
          // This ensures we only get *valid* applications and ignore old test data
          where("status", "in", ["pending", "hired", "rejected", "completed"]),
          orderBy("appliedAt", "desc")
        );
        const querySnapshot = await getDocs(q);
        const appsData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        
        setApplications(appsData); // Update state with *clean* applications
      } catch (err) {
        // Handle potential Firestore index errors
        if (err.code === 'failed-precondition') {
             console.error("Firestore index missing for MyApplications:", err);
             setError("Database index is missing or building. Please check Firebase console or wait a few minutes.");
        } else {
            console.error("Error fetching applications:", err);
            setError("Could not load applications.");
        }
       }
      finally { setLoading(false); } // Ensure loading is set to false
    };

  // Run fetchApplications when the user object changes (e.g., on login)
  useEffect(() => {
    fetchApplications();
  }, [user]);

  // Memoized calculation to filter applications based on the active tab
  const filteredApplications = useMemo(() => {
    if (filter === 'All') { return applications; } // 'applications' is already pre-filtered
    const filterStatus = filter.toLowerCase(); 
    return applications.filter(app => app.status === filterStatus);
  }, [applications, filter]); 

  // Function to handle withdrawing an application
  const handleWithdraw = async (appId) => {
    // Confirmation dialog
    if (!window.confirm("Are you sure you want to withdraw this application?")) { return; }
    try {
      setActionMessage("Withdrawing..."); // Provide feedback
      await deleteDoc(doc(db, "applications", appId)); // Delete the document from Firestore
      // Update local state immediately for better UX
      setApplications(prev => prev.filter(app => app.id !== appId));
      setActionMessage("Application withdrawn.");
    } catch (err) {
      console.error("Error withdrawing application:", err);
      setActionMessage("Error withdrawing application. Please try again.");
    }
  };

  // handleRateGiver
  const handleRateGiver = async (giverId, ratingValue, applicationId) => {
    setActionMessage("Submitting rating...");
    try {
      // Use Firestore transaction for atomic updates
      await runTransaction(db, async (transaction) => {
        const giverRef = doc(db, "users", giverId);
        const applicationRef = doc(db, "applications", applicationId);

        // Prepare updates for the Giver's document
        const giverUpdates = {
          totalRatingScore: increment(ratingValue), // Atomically increment score
          numberOfRatings: increment(1),         // Atomically increment count
        };

        // Update Giver document
        transaction.update(giverRef, giverUpdates);
        
        // Update Application document to mark as rated by the quester
        transaction.update(applicationRef, {
            questerRating: ratingValue, // Store the rating given
            questerRated: true,         // Set the flag
        });
      }); // End transaction
      setActionMessage("Rating submitted successfully!");
      fetchApplications(); // Refresh list to update UI (hide rating input)

    } catch (err) {
      console.error("Error submitting rating:", err);
      setActionMessage("Error submitting rating. Please try again.");
    }
  };

  // Memoized calculation for sidebar stats
  const stats = useMemo(() => {
    return applications.reduce((acc, app) => {
      acc[app.status] = (acc[app.status] || 0) + 1;
      return acc;
    }, { pending: 0, hired: 0, rejected: 0, completed: 0 }); // Initialize counts
  }, [applications]); // Rerun when applications change


  // Display loading state while user data is fetched
  if (!user) { return <div className="bq-container" style={{padding: "2rem"}}>Loading...</div>; }

  // Determine avatar source for the sidebar
  const avatarSrc = user.avatarUrl || `https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random`;

  // Render the page
  return (
    <div className="bq-container">
      <div className="my-applications-layout">

        {/* Left Sidebar */}
        <aside className="profile-sidebar">
          <img src={avatarSrc} alt={user.name} className="profile-avatar" />
          <h2>{user.name}</h2>
          <p>{user.email}</p>
          {/* Display Stats */}
          <div className="profile-stats">
            <div className="stat-item"> <span className="stat-value">{stats.pending || 0}</span> <span className="stat-label">Pending</span> </div>
            <div className="stat-item"> <span className="stat-value">{stats.hired || 0}</span> <span className="stat-label">Hired</span> </div>
            <div className="stat-item"> <span className="stat-value">{stats.completed || 0}</span> <span className="stat-label">Completed</span> </div>
            <div className="stat-item"> <span className="stat-value">{stats.rejected || 0}</span> <span className="stat-label">Rejected</span> </div>
          </div>
        </aside>

        {/* Right Panel */}
        <main className="applications-panel">
          <h1>My Applications</h1>

          {/* Filter Tabs */}
          <div className="tabs">
            {['All', 'Pending', 'Hired', 'Rejected', 'Completed'].map(tab => (
              <button key={tab} className={`tab-button ${filter === tab ? 'active' : ''}`} onClick={() => setFilter(tab)} > {tab} </button>
            ))}
          </div>

          {/* Loading/Error/Action Messages */}
          {loading && <p>Loading applications...</p>}
          {error && <p style={{color: '#ff8a8a'}}>{error}</p>}
          {actionMessage && <p style={{color: 'var(--accent)'}}>{actionMessage}</p>}

          {/* No Applications Message */}
          {!loading && filteredApplications.length === 0 && (
            <p>You haven't applied to any quests yet{filter !== 'All' ? ` with status "${filter}"` : ''}.</p>
          )}

          {/* Application List */}
          <div className="applications-list">
            {!loading && filteredApplications.map(app => (
              <ApplicationItem // Use the dedicated component
                key={app.id}
                application={app}
                onWithdraw={handleWithdraw}
                onRateGiver={handleRateGiver} // Pass the handler
              />
            ))}
          </div>

        </main>
      </div>
    </div>
  );
}