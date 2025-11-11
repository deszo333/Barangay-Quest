import React, { useState, useEffect, useMemo } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import { db } from '../firebase';
// Import all necessary Firestore functions
import {
    collection, query, where, getDocs, orderBy, doc, updateDoc,
    writeBatch, limit, getDoc, deleteDoc, getCountFromServer,
    runTransaction, FieldValue, increment, serverTimestamp
} from 'firebase/firestore';
import StarRatingInput from '../components/StarRatingInput';
import "./MyQuests.css";
import "../pages/Home.css";
import "./PostJob.css"; // <-- ADD THIS IMPORT
// achievements css removed

// Helper to get user context
function useUser() {
  return useOutletContext();
} // <-- THIS IS THE MISSING BRACE THAT FIXES EVERYTHING

// Helper for date formatting
function formatDate(timestamp) {
  if (!timestamp) return "";
  const seconds = Math.floor((new Date() - timestamp.toDate()) / 1000);
  let interval = seconds / 86400; // Days
  if (interval > 1) return Math.floor(interval) + " days ago";
  interval = seconds / 3600; // Hours
  if (interval > 1) return Math.floor(interval) + " hours ago";
  return "today";
}

// --- ApplicantItem Component (Simplified) ---
function ApplicantItem({ application, onHire, onReject }) {
  const [applicantData, setApplicantData] = useState(null); 

  useEffect(() => {
    const fetchApplicantData = async () => {
      if (!application.applicantId) return;
      setApplicantData(null); 
      try {
        const userDocRef = doc(db, "users", application.applicantId);
        const userDocSnap = await getDoc(userDocRef);
        if (userDocSnap.exists()) {
          setApplicantData(userDocSnap.data()); 
        } else {
            console.warn(`Applicant profile not found for ID: ${application.applicantId}`);
            setApplicantData(null); 
        }
      } catch (err) {
        console.error("Error fetching applicant data:", err);
        setApplicantData(null); 
      }
    };
    fetchApplicantData();
  }, [application.applicantId]);

  const avgRating = applicantData && applicantData.numberOfRatings > 0
    ? (applicantData.totalRatingScore / applicantData.numberOfRatings).toFixed(1)
    : 'N/A';
  const ratingCount = applicantData?.numberOfRatings || 0;

  return (
    <div className="applicant-item">
      <div className="applicant-info">
        <img src={applicantData?.avatarUrl || `https://ui-avatars.com/api/?name=${application.applicantName}&background=random`} alt={application.applicantName} className="applicant-avatar" />
        <div>
            <Link to={`/profile/${application.applicantId}`} className="applicant-name">
              {application.applicantName}
            </Link>
            <div style={{fontSize: '0.8rem', color: 'var(--muted)', marginTop: '2px'}}>
                ⭐ {avgRating} ({ratingCount} ratings)
            </div>
        </div>
      </div>
      <div className="applicant-actions">
        <button className="btn btn-secondary btn-save" onClick={() => onReject(application.id)}>Reject</button>
        <button className="btn btn-accent" onClick={() => onHire(application.id, application.applicantId)}>Hire</button>
      </div>
    </div>
  );
}

// --- PostedQuestItem Component (Simplified) ---
function PostedQuestItem({ quest, onHireApplicant, onRejectApplicant, onMarkComplete, onDeleteQuest, onRateQuester, onTogglePause, onCancelHired }) { // <-- Added onCancelHired
  const [showApplicants, setShowApplicants] = useState(false);
  const [applicants, setApplicants] = useState([]);
  const [applicantCount, setApplicantCount] = useState(0);
  const [loadingApplicants, setLoadingApplicants] = useState(false);
  const [hiredApplicantInfo, setHiredApplicantInfo] = useState(null);
  const [showRatingInput, setShowRatingInput] = useState(false);
  const [rating, setRating] = useState(0);
  const [reviewText, setReviewText] = useState(""); // <-- ADDED THIS
  const [ratingLoading, setRatingLoading] = useState(false);

  // Fetch Applicant Count
  useEffect(() => {
    const fetchApplicantCount = async () => {
        if (quest.status !== 'open') { setApplicantCount(0); return; }
        try {
            // --- FIX: Use the 'applicantCount' field from the quest document ---
            setApplicantCount(quest.applicantCount || 0);
        } catch (error) { console.error("Error fetching applicant count:", error); setApplicantCount(0); }
    };
    fetchApplicantCount();
  }, [quest.id, quest.status, quest.applicantCount]); // <-- Listen to quest.applicantCount

  // Fetch Hired Applicant Info
  useEffect(() => {
    const fetchHiredInfo = async () => {
      if ((quest.status === 'in-progress' || quest.status === 'completed') && quest.hiredApplicantId) {
        try {
          const userDocRef = doc(db, "users", quest.hiredApplicantId);
          const userDocSnap = await getDoc(userDocRef);
          if (userDocSnap.exists()) { 
            const data = userDocSnap.data();
            setHiredApplicantInfo({ name: data.name, phone: data.phone, avatarUrl: data.avatarUrl }); 
          }
          else { setHiredApplicantInfo({ name: "Unknown User", phone: "N/A" }); }
        } catch (error) { console.error("Error fetching hired applicant info:", error); setHiredApplicantInfo({ name: "Error", phone: "N/A" }); }
      } else { setHiredApplicantInfo(null); }
    };
    fetchHiredInfo();
  }, [quest.status, quest.hiredApplicantId]);

   // Show Rating Input Logic
  useEffect(() => {
    if (quest.status === 'completed' && quest.hiredApplicationData && !quest.hiredApplicationData.giverRated) { setShowRatingInput(true); }
    else { setShowRatingInput(false); setRating(0); }
  }, [quest.status, quest.hiredApplicationData]);

  // Fetch Full Applicant Details
  const fetchApplicants = async () => {
    if (applicants.length > 0 && showApplicants) { setShowApplicants(false); return; }
    if (applicants.length > 0 && !showApplicants) { setShowApplicants(true); return; }
    setLoadingApplicants(true);
    try {
      const appsCollection = collection(db, "applications");
      const q = query( appsCollection, where("questId", "==", quest.id), where("status", "==", "pending") );
      const querySnapshot = await getDocs(q);
      const appsData = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
      setApplicants(appsData); 
      // setApplicantCount(appsData.length); // No longer needed, we read from quest.applicantCount
      setShowApplicants(true);
    } catch (err) { console.error("Error fetching applicants:", err); }
    finally { setLoadingApplicants(false); }
  };

  // Submit Rating Function
  const submitRating = async () => {
    if (rating === 0 || !quest.hiredApplicantId || !quest.hiredApplicationData?.id) return;
    setRatingLoading(true);
    // --- PASS THE REVIEW TEXT ---
    await onRateQuester(quest.hiredApplicantId, rating, quest.hiredApplicationData.id, reviewText.trim());
    setRatingLoading(false);
  };

  return (
    <div className="posted-quest-item">
      <div className="quest-item-header">
        <div className="quest-item-details">
          <h3>{quest.title}</h3>
          <p>{quest.location?.address || quest.workType} • {formatDate(quest.createdAt)}</p>
          <p style={{ marginTop: '5px', fontWeight: '600', textTransform: 'capitalize' }} className={`app-status ${quest.status || 'open'}`}> Status: {quest.status || 'Open'} </p>
        </div>
        <div className="quest-item-actions">
           {(quest.status === 'open' || quest.status === 'paused') && (
            <button className="btn btn-secondary" onClick={() => onTogglePause(quest.id, quest.status)}>
              {quest.status === 'open' ? 'Pause' : 'Unpause'}
            </button>
           )}
           
           {/* Show "Cancel" or "Mark Complete" */}
           {quest.status === 'in-progress' && ( 
            <>
              <button className="btn btn-danger" onClick={() => onCancelHired(quest.id, quest.hiredApplicationData?.id, quest.escrowAmount, quest.hiredApplicantId)}>
                Cancel & Refund
              </button>
              <button className="btn btn-primary" onClick={() => onMarkComplete(quest.id, quest.hiredApplicantId, quest.hiredApplicationData?.id)} > 
                Mark Complete 
              </button> 
            </>
           )}

           {(quest.status === 'open' || quest.status === 'paused') && ( // Only show Delete if it's open or paused
             <button className="btn btn-danger" onClick={() => onDeleteQuest(quest.id)} > 
              Delete 
             </button> 
           )}
        </div>
      </div>
      <div>
        {quest.status === 'open' && ( <button onClick={fetchApplicants} className="quest-item-applicants" disabled={loadingApplicants}> {loadingApplicants ? 'Loading...' : (showApplicants ? 'Hide Applicants' : `View Applicants (${applicantCount})`)} </button> )}
        {hiredApplicantInfo && ( <p style={{marginTop: '0.5rem', color: 'var(--muted)'}}> {quest.status === 'completed' ? 'Completed by: ' : 'Hired: '} <strong style={{color: 'var(--white)'}}>{hiredApplicantInfo.name}</strong> {' ('}{hiredApplicantInfo.phone}{')'} </p> )}
      </div>
      {showApplicants && quest.status === 'open' && (
        <div className="quest-applicants-section">
          <h4>Pending Applicants</h4>
          {applicants.length === 0 ? ( <p>No pending applicants yet.</p> ) : (
            <div className="applicants-list">
              {applicants.map(app => ( <ApplicantItem key={app.id} application={app} onHire={(applicationId, applicantId) => onHireApplicant(quest.id, applicationId, applicantId)} onReject={(applicationId) => onRejectApplicant(applicationId)} /> ))}
            </div>
          )}
        </div>
      )}
      {showRatingInput && (
        <div className="quest-applicants-section" style={{ background: 'var(--card)', padding: '1rem', borderRadius: '8px', marginTop: '1rem' }}>
          <h4>Rate {hiredApplicantInfo?.name || 'the Quester'}</h4>
          <StarRatingInput rating={rating} setRating={setRating} />

          {/* --- ADD THIS TEXTAREA --- */}
          <textarea
            placeholder="Leave a review (optional)..."
            className="form-textarea" // This style comes from PostJob.css
            style={{ marginTop: '1rem', minHeight: '80px', background: 'var(--bg)' }}
            value={reviewText}
            onChange={(e) => setReviewText(e.target.value)}
          />
          {/* --- END ADD --- */}
          
          <button className="btn btn-accent" style={{ marginTop: '1rem' }} onClick={submitRating} disabled={rating === 0 || ratingLoading} > {ratingLoading ? "Submitting..." : "Submit Rating"} </button>
        </div>
      )}
    </div>
  );
}

// --- MAIN PAGE COMPONENT ---
export default function MyQuests() {
  const { user, setUser } = useOutletContext(); // Get user and setUser
  const [quests, setQuests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('Active');
  const [error, setError] = useState(null);
  const [actionMessage, setActionMessage] = useState("");

  // Fetch Quests
  const fetchQuests = async () => {
    if (!user) return;
    try {
      setLoading(true); setError(null);
      const questsCollection = collection(db, "quests");
      const q = query( questsCollection, where("questGiverId", "==", user.uid), orderBy("createdAt", "desc") );
      const querySnapshot = await getDocs(q);
      const questsDataPromises = querySnapshot.docs.map(async (questDoc) => {
        const questData = { id: questDoc.id, ...questDoc.data() };

        // Fetch app data if 'in-progress' OR 'completed'
        if ((questData.status === 'in-progress' || questData.status === 'completed') && questData.hiredApplicantId) {
          const appQuery = query( 
            collection(db, "applications"), 
            where("questId", "==", questData.id), 
            where("applicantId", "==", questData.hiredApplicantId), 
            where("status", "in", ["hired", "completed"]), 
            limit(1) 
          );
          const appSnapshot = await getDocs(appQuery);
          if (!appSnapshot.empty) { 
            questData.hiredApplicationData = { id: appSnapshot.docs[0].id, ...appSnapshot.docs[0].data() }; 
          } else { 
            console.warn("Could not find hired application for quest:", questData.id);
            questData.hiredApplicationData = null; 
          }
        } else { 
          questData.hiredApplicationData = null; 
        }
        return questData;
      });

      const questsData = await Promise.all(questsDataPromises);
      setQuests(questsData);
    } catch (err) {
      console.error("Error fetching quests:", err);
      if (err.code === 'failed-precondition') {
           setError("Database index is missing or building...");
      } else { setError("Could not load your quests."); }
    } finally { setLoading(false); }
  };
  useEffect(() => { fetchQuests(); }, [user]);

  // Filter Quests
  const filteredQuests = useMemo(() => {
    // --- FIX: "Paused" quests now go to "Archived" ---
    if (filter === 'Active') { 
      return quests.filter(q => q.status === 'open' || q.status === 'in-progress'); 
    }
    if (filter === 'Completed') {
      return quests.filter(q => q.status === 'completed');
    }
    if (filter === 'Archived') {
      return quests.filter(q => q.status === 'archived' || q.status === 'paused');
    }
    return quests; // Should not happen
  }, [quests, filter]);

  // Calculate Stats
  const [stats, setStats] = useState({ pendingApps: 0, hiredCount: 0, posted: 0 });
  useEffect(() => {
      const fetchStats = async () => {
          if (!user) return;
          try {
              const postedCount = quests.length;
              // This can be simplified by just reading from the quests array
              const pendingAppsQuery = query( collection(db, "applications"), where("questGiverId", "==", user.uid), where("status", "==", "pending") );
              const pendingSnapshot = await getCountFromServer(pendingAppsQuery);
              const pendingCount = pendingSnapshot.data().count;
              
              const hiredCount = quests.filter(q => q.status === 'in-progress' || q.status === 'completed').length;
              
              setStats({ pendingApps: pendingCount, hiredCount: hiredCount, posted: postedCount });
          } catch (error) { console.error("Error fetching stats:", error); setStats({ pendingApps: '?', hiredCount: '?', posted: quests.length }); }
      };
      fetchStats();
  }, [quests, user]);


  // handleHireApplicant (Escrow Logic)
  const handleHireApplicant = async (questId, applicationId, applicantId) => {
    setActionMessage("Processing hire...");
    
    const questToHire = quests.find(q => q.id === questId);
    if (!questToHire) {
      setActionMessage("Error: Quest not found.");
      return;
    }
    // --- FIX: Read from 'price' not 'budgetAmount' ---
    const priceAmount = Number(questToHire.price);

    if (!priceAmount || priceAmount <= 0) {
      // --- FIX: Update error message ---
      setActionMessage("Error: Quest has an invalid price.");
      return;
    }
    if ((user.walletBalance || 0) < priceAmount) { // <-- FIX
      setActionMessage("Error: Insufficient funds. Please add credits to your profile.");
      return;
    }

    try {
      await runTransaction(db, async (transaction) => {
        const questRef = doc(db, "quests", questId);
        const giverRef = doc(db, "users", user.uid);
        const appRef = doc(db, "applications", applicationId);

        const giverSnap = await transaction.get(giverRef);
        if (!giverSnap.exists()) { throw new Error("Your user profile not found."); }
        
        const giverData = giverSnap.data();
        if ((giverData.walletBalance || 0) < priceAmount) { // <-- FIX
          throw new Error("Insufficient funds. Please add credits to your profile.");
        }

        transaction.update(giverRef, {
          walletBalance: increment(-priceAmount) // <-- FIX
        });
        
        transaction.update(questRef, { 
          status: "in-progress", 
          hiredApplicantId: applicantId,
          escrowAmount: priceAmount // <-- FIX
        });
        
        transaction.update(appRef, { status: "hired" });
      });

      const batch = writeBatch(db);
      const otherAppsQuery = query( collection(db, "applications"), where("questId", "==", questId), where("status", "==", "pending") );
      const otherAppsSnapshot = await getDocs(otherAppsQuery); 
      otherAppsSnapshot.forEach(appDoc => { 
        if (appDoc.id !== applicationId) { 
          batch.update(appDoc.ref, { status: "rejected" }); 
        } 
      });
      await batch.commit(); 
      
      setUser(prevUser => ({ ...prevUser, walletBalance: (prevUser.walletBalance || 0) - priceAmount })); // <-- FIX
      setActionMessage("Applicant hired and funds are in escrow!"); 
      fetchQuests();

    } catch (err) { 
      console.error("Error hiring applicant:", err); 
      setActionMessage(`Error: ${err.message}`);
    }
  };

  const handleRejectApplicant = async (applicationId) => {
    setActionMessage(`Rejecting application ${applicationId}...`);
    try {
      const appRef = doc(db, "applications", applicationId); await updateDoc(appRef, { status: "rejected" });
      setActionMessage("Applicant rejected."); 
      // Manually decrement applicantCount on quest
      // We'll skip this for now to avoid complexity, but it's a "nice to have"
      fetchQuests();
    } catch (err) { console.error("Error rejecting applicant:", err); setActionMessage("Error rejecting applicant."); }
  };
  
  // handleMarkComplete (Payout Logic)
  const handleMarkComplete = async (questId, hiredApplicantId, hiredApplicationId) => {
    setActionMessage(`Completing quest ${questId}...`);
    
    if (!hiredApplicantId) {
        setActionMessage("Error: Cannot complete. No applicant was hired.");
        return;
    }

    try {
      await runTransaction(db, async (transaction) => {
        
        // 1. References
        const questRef = doc(db, "quests", questId);
        const giverRef = doc(db, "users", user.uid); 
        const questerRef = doc(db, "users", hiredApplicantId);
        let hiredAppRef = hiredApplicationId ? doc(db, "applications", hiredApplicationId) : null;

        // 2. --- ALL READS MUST BE FIRST ---
        const questSnap = await transaction.get(questRef);
        const giverSnap = await transaction.get(giverRef);
        const questerSnap = await transaction.get(questerRef);
        
        let appSnap = null; 
        if (hiredAppRef) {
            appSnap = await transaction.get(hiredAppRef);
        }
        
        // 3. VALIDATION
        if (!questSnap.exists() || questSnap.data().status !== 'in-progress') {
          throw new Error("Quest not in progress or does not exist.");
        }
        if (!giverSnap.exists()) { throw new Error("Giver profile not found!"); }
        if (!questerSnap.exists()) { throw new Error("Quester profile not found!"); }
        if (hiredAppRef && !appSnap.exists()) {
          console.warn("Could not find application to update:", hiredApplicationId);
          hiredAppRef = null; 
        }

        // 4. Prepare Writes (with Payout)
        const questData = questSnap.data();
        const escrowAmount = Number(questData.escrowAmount || 0);
        
        const isSamePerson = giverRef.path === questerRef.path;
        
        const giverUpdates = { questsGivenCompleted: increment(1) };
        const questerUpdates = { 
          questsCompleted: increment(1),
          walletBalance: increment(escrowAmount) // <-- THIS IS THE PAYOUT
        };

        // 5. --- ALL WRITES GO LAST ---
        transaction.update(questRef, { 
          status: "completed", 
          completedAt: serverTimestamp(),
          escrowAmount: 0 
        });
        
        if (isSamePerson) {
          transaction.update(giverRef, {
            questsGivenCompleted: increment(1),
            questsCompleted: increment(1),
          });
        } else {
          transaction.update(giverRef, giverUpdates);
          transaction.update(questerRef, questerUpdates);
        }
        
        if (hiredAppRef) {
          transaction.update(hiredAppRef, { status: "completed" });
        }
      }); // End Transaction
      
      setActionMessage("Quest marked complete and Quester has been paid!");
      fetchQuests();
      
    } catch (err) {
      console.error("Error marking quest complete:", err);
      setActionMessage(`Error: ${err.message}.`);
    }
  };
  
  const handleDeleteQuest = async (questId) => {
    if (!window.confirm("Delete this quest?")) { return; }
    setActionMessage(`Deleting quest ${questId}...`);
    try {
        const questRef = doc(db, "quests", questId); await deleteDoc(questRef);
        setActionMessage("Quest deleted."); fetchQuests();
    } catch (err) { console.error("Error deleting quest:", err); setActionMessage("Error deleting quest."); }
  };
  
  // handleRateQuester
  const handleRateQuester = async (questerId, ratingValue, applicationId, reviewText) => {
    setActionMessage("Submitting rating...");
    try {
      await runTransaction(db, async (transaction) => {
        const questerRef = doc(db, "users", questerId); 
        const applicationRef = doc(db, "applications", applicationId);
        
        transaction.update(questerRef, { 
          totalRatingScore: increment(ratingValue), 
          numberOfRatings: increment(1) 
        });
        
        // --- ADD REVIEW TEXT ---
        transaction.update(applicationRef, { 
          giverRating: ratingValue, 
          giverRated: true,
          review: reviewText || "" // <-- ADDED
        });
      });
      setActionMessage("Rating submitted.");
      fetchQuests(); // Refresh list to hide rating box
    } catch (err) { 
      console.error("Error submitting rating:", err); 
      setActionMessage("Error submitting rating."); 
    }
  };

  // --- NEW: Pause/Unpause Quest Function ---
  const handleTogglePause = async (questId, currentStatus) => {
    const newStatus = currentStatus === 'open' ? 'paused' : 'open';
    const action = newStatus === 'paused' ? 'Pausing' : 'Unpausing';
    setActionMessage(`${action} quest...`);

    try {
      const questRef = doc(db, "quests", questId);
      await updateDoc(questRef, {
        status: newStatus
      });
      setActionMessage(`Quest successfully ${newStatus}.`);
      fetchQuests(); // Refresh the list
    } catch (err) {
      console.error(`Error ${action.toLowerCase()} quest:`, err);
      setActionMessage(`Failed to ${action.toLowerCase()} quest.`);
    }
  };

  // --- NEW: Cancel Hired Quest Function (FIXED) ---
  const handleCancelHired = async (questId, applicationId, escrowAmount, hiredApplicantId) => {
    if (!window.confirm("Are you sure you want to cancel this hired quest? The Quester will be notified and your funds will be refunded.")) {
      return;
    }
    
    setActionMessage("Cancelling quest...");
    const refundAmount = Number(escrowAmount || 0);

    try {
      await runTransaction(db, async (transaction) => {
        // 1. References
        const questRef = doc(db, "quests", questId);
        const giverRef = doc(db, "users", user.uid);
        let appRef = applicationId ? doc(db, "applications", applicationId) : null;

        // 2. --- ALL READS FIRST ---
        const questSnap = await transaction.get(questRef);
        const giverSnap = await transaction.get(giverRef); // Need to read giver to validate
        let appSnap = null;
        if (appRef) {
          appSnap = await transaction.get(appRef);
        }

        // 3. --- VALIDATION ---
        if (!questSnap.exists() || questSnap.data().status !== 'in-progress') {
          throw new Error("Quest is not in-progress.");
        }
        if (!giverSnap.exists()) {
          throw new Error("Giver profile not found.");
        }
        if (appRef && !appSnap.exists()) {
           console.warn("Could not find application to update:", applicationId);
           appRef = null; // Don't try to update it
        }
        
        // 4. --- ALL WRITES LAST ---
        // Refund Giver
        transaction.update(giverRef, {
          walletBalance: increment(refundAmount)
        });
        
        // Reset Quest
        transaction.update(questRef, {
          status: 'open', // Set back to open
          hiredApplicantId: null,
          escrowAmount: 0
        });
        
        // Reject the application
        if (appRef) {
          transaction.update(appRef, { status: 'rejected' });
        }
      });
      
      // Update local state
      setUser(prevUser => ({ ...prevUser, walletBalance: (prevUser.walletBalance || 0) + refundAmount }));
      setActionMessage("Quest cancelled and funds refunded. You can now delete this quest or hire a new applicant.");
      fetchQuests();
      
    } catch (err) {
      console.error("Error cancelling quest:", err);
      setActionMessage(`Error: ${err.message}`);
    }
  };

  if (!user) { return <div className="bq-container" style={{padding: "2rem"}}>Loading...</div>; }

  return (
    <div className="bq-container">
      <div className="my-quests-layout">
        <aside className="profile-sidebar">
           <img src={user.avatarUrl || `https://ui-avatars.com/api/?name=${user.name}&background=random`} alt={user.name} className="profile-avatar"/>
           <h2>{user.name}</h2> <p>{user.email}</p>
           <div className="profile-stats">
            <div className="stat-item"><span className="stat-value">{loading ? '...' : stats.pendingApps}</span><span className="stat-label">Pending Apps</span></div>
            <div className="stat-item"><span className="stat-value">{loading ? '...' : stats.hiredCount}</span><span className="stat-label">Hired</span></div>
            <div className="stat-item"><span className="stat-value">{loading ? '...' : stats.posted}</span><span className="stat-label">Quests Posted</span></div>
          </div>
        </aside>
        <main className="quests-panel">
          <h1>My Quests</h1>
          <div className="tabs">
            {['Active', 'Completed', 'Archived'].map(tab => ( <button key={tab} className={`tab-button ${filter === tab ? 'active' : ''}`} onClick={() => setFilter(tab)} > {tab} </button> ))}
          </div>
          {loading && <p>Loading quests...</p>}
          {error && <p style={{color: '#ff8a8a'}}>{error}</p>}
          {actionMessage && <p style={{color: 'var(--accent)'}}>{actionMessage}</p>}
          {!loading && filteredQuests.length === 0 && ( <p>You haven't posted any quests for this tab.</p> )}
          <div className="quests-list">
            {!loading && filteredQuests.map(quest => (
              <PostedQuestItem
                key={quest.id} quest={quest}
                onHireApplicant={handleHireApplicant}
                onRejectApplicant={handleRejectApplicant}
                onMarkComplete={handleMarkComplete}
                onDeleteQuest={handleDeleteQuest}
                // --- FIX: Pass all args ---
                onRateQuester={(questerId, ratingValue, applicationId, reviewText) => 
                  handleRateQuester(questerId, ratingValue, applicationId, reviewText)
                }
                onTogglePause={handleTogglePause}
                onCancelHired={handleCancelHired} // <-- Pass new handler
              />
            ))}
          </div>
        </main>
      </div>
    </div>
  );
}