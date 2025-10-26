import React, { useState, useEffect, useMemo } from 'react';
import { useOutletContext, Link } from 'react-router-dom';
import { db } from '../firebase';
// Import all necessary Firestore functions
import {
    collection, query, where, getDocs, orderBy, doc, updateDoc,
    writeBatch, limit, getDoc, deleteDoc, getCountFromServer,
    runTransaction, FieldValue, increment, serverTimestamp, arrayUnion
} from 'firebase/firestore';
import StarRatingInput from '../components/StarRatingInput';
import "./MyQuests.css";
import "../pages/Home.css";
import '../pages/AchievementsPage.css'; // Import badge style

// Helper to get user context
function useUser() {
  return useOutletContext();
}

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

// Badge Definitions
const ACHIEVEMENT_BADGES = {
    'seasoned_quester_2': 'ЁЯМЯ',
    'top_rated': 'ЁЯПЖ',
    'quest_giver_2': ' M' // Placeholder
};
function getUserBadges(user) {
    if (!user || !user.unlockedAchievements) return [];
    return user.unlockedAchievements.filter(id => ACHIEVEMENT_BADGES[id]).map(id => ({ id, icon: ACHIEVEMENT_BADGES[id] }));
}

// --- ApplicantItem Component ---
function ApplicantItem({ application, onHire, onReject }) {
  // --- CORRECTED useState line ---
  const [applicantData, setApplicantData] = useState(null); // State for full applicant data

  // Fetch applicant's full data (including rating and achievements)
  useEffect(() => {
    const fetchApplicantData = async () => {
      if (!application.applicantId) return;
      setApplicantData(null); // Reset on ID change
      try {
        const userDocRef = doc(db, "users", application.applicantId);
        const userDocSnap = await getDoc(userDocRef);
        if (userDocSnap.exists()) {
          setApplicantData(userDocSnap.data()); // Store all data
        } else {
            console.warn(`Applicant profile not found for ID: ${application.applicantId}`);
            setApplicantData(null); // Keep null if not found
        }
      } catch (err) {
        console.error("Error fetching applicant data:", err);
        setApplicantData(null); // Keep null on error
      }
    };
    fetchApplicantData();
  }, [application.applicantId]);

  // Calculate average rating
  const avgRating = applicantData && applicantData.numberOfRatings > 0
    ? (applicantData.totalRatingScore / applicantData.numberOfRatings).toFixed(1)
    : 'N/A';
  const ratingCount = applicantData?.numberOfRatings || 0;
  const badges = getUserBadges(applicantData); // Get badges from the fetched data

  return (
    <div className="applicant-item">
      <div className="applicant-info">
        <img src={`https://ui-avatars.com/api/?name=${application.applicantName}&background=random`} alt={application.applicantName} className="applicant-avatar" />
        <div>
            <Link to={`/profile/${application.applicantId}`} className="applicant-name">
              {application.applicantName}
              {/* Display Badges */}
              {badges.map(badge => (
                  <span key={badge.id} className="user-badge" title={badge.id.replace(/_/g, ' ')}> {badge.icon} </span>
              ))}
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

// --- PostedQuestItem Component ---
function PostedQuestItem({ quest, onHireApplicant, onRejectApplicant, onMarkComplete, onDeleteQuest, onRateQuester }) {
  const [showApplicants, setShowApplicants] = useState(false);
  const [applicants, setApplicants] = useState([]);
  const [applicantCount, setApplicantCount] = useState(0);
  const [loadingApplicants, setLoadingApplicants] = useState(false);
  const [hiredApplicantInfo, setHiredApplicantInfo] = useState(null);
  const [showRatingInput, setShowRatingInput] = useState(false);
  const [rating, setRating] = useState(0);
  const [ratingLoading, setRatingLoading] = useState(false);

  // Fetch Applicant Count
  useEffect(() => {
    const fetchApplicantCount = async () => {
        if (quest.status !== 'open') { setApplicantCount(0); return; }
        try {
            const appsCollection = collection(db, "applications");
            const q = query( appsCollection, where("questId", "==", quest.id), where("status", "==", "pending") );
            const countSnapshot = await getCountFromServer(q);
            setApplicantCount(countSnapshot.data().count);
        } catch (error) { console.error("Error fetching applicant count:", error); setApplicantCount(0); }
    };
    fetchApplicantCount();
  }, [quest.id, quest.status]);

  // Fetch Hired Applicant Info
  useEffect(() => {
    const fetchHiredInfo = async () => {
      if ((quest.status === 'in-progress' || quest.status === 'completed') && quest.hiredApplicantId) {
        try {
          const userDocRef = doc(db, "users", quest.hiredApplicantId);
          const userDocSnap = await getDoc(userDocRef);
          if (userDocSnap.exists()) { setHiredApplicantInfo({ name: userDocSnap.data().name, phone: userDocSnap.data().phone }); }
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
      setApplicants(appsData); setApplicantCount(appsData.length); setShowApplicants(true);
    } catch (err) { console.error("Error fetching applicants:", err); }
    finally { setLoadingApplicants(false); }
  };

  // Submit Rating Function
  const submitRating = async () => {
    if (rating === 0 || !quest.hiredApplicantId || !quest.hiredApplicationData?.id) return;
    setRatingLoading(true);
    await onRateQuester(quest.hiredApplicantId, rating, quest.hiredApplicationData.id);
    setRatingLoading(false);
  };

  return (
    <div className="posted-quest-item">
      <div className="quest-item-header">
        <div className="quest-item-details">
          <h3>{quest.title}</h3>
          <p>{quest.location?.address || quest.workType} тАв {formatDate(quest.createdAt)}</p>
          <p style={{ marginTop: '5px', fontWeight: '600', textTransform: 'capitalize' }} className={`app-status ${quest.status || 'open'}`}> Status: {quest.status || 'Open'} </p>
        </div>
        <div className="quest-item-actions">
           {quest.status === 'open' && <button className="btn btn-secondary">Pause</button>}
           {quest.status !== 'completed' && quest.status !== 'archived' && <button className="btn btn-outline">Edit</button>}
           {/* --- MODIFIED LINE --- */}
           {quest.status === 'in-progress' && ( <button className="btn btn-primary" onClick={() => onMarkComplete(quest.id, quest.hiredApplicantId, quest.hiredApplicationData?.id)} > Mark Complete </button> )}
           {quest.status === 'open' && ( <button className="btn btn-danger" onClick={() => onDeleteQuest(quest.id)} > Delete </button> )}
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
          <button className="btn btn-accent" style={{ marginTop: '1rem' }} onClick={submitRating} disabled={rating === 0 || ratingLoading} > {ratingLoading ? "Submitting..." : "Submit Rating"} </button>
        </div>
      )}
    </div>
  );
}

// --- MAIN PAGE COMPONENT ---
export default function MyQuests() {
  const { user } = useUser();
  const [quests, setQuests] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('Active');
  const [error, setError] = useState(null);
  const [actionMessage, setActionMessage] = useState("");

  // Fetch Quests
  const fetchQuests = async () => {
    if (!user) return;
    try {
      setLoading(true); setError(null); setActionMessage("");
      const questsCollection = collection(db, "quests");
      const q = query( questsCollection, where("questGiverId", "==", user.uid), orderBy("createdAt", "desc") );
      const querySnapshot = await getDocs(q);
      const questsDataPromises = querySnapshot.docs.map(async (questDoc) => {
        const questData = { id: questDoc.id, ...questDoc.data() };
        if (questData.status === 'completed' && questData.hiredApplicantId) {
          const appQuery = query( collection(db, "applications"), where("questId", "==", questData.id), where("applicantId", "==", questData.hiredApplicantId), limit(1) );
          const appSnapshot = await getDocs(appQuery);
          if (!appSnapshot.empty) { questData.hiredApplicationData = { id: appSnapshot.docs[0].id, ...appSnapshot.docs[0].data() }; }
           else { questData.hiredApplicationData = null; }
        } else { questData.hiredApplicationData = null; }
        return questData;
      });
      const questsData = await Promise.all(questsDataPromises);
      setQuests(questsData);
    } catch (err) {
      console.error("Error fetching quests:", err);
      if (err.code === 'failed-precondition') {
           console.error("Firestore index missing for MyQuests:", err);
           console.log("Create index here:", `https://console.firebase.google.com/v1/r/project/${db.app.options.projectId}/firestore/indexes?create_composite=ClVwcm9qZWN0cy9iYXJhbmdheS1xdWVzdC9kYXRhYmFzZXMvKGRlZmF1bHQpL2NvbGxlY3Rpb25Hcm91cHMvcXVlc3RzL2luZGV4ZXMvXxABGhAKDHJlc3RBcG9Vc2VyEAEaDQoJY3JlYXRlZEF0EAIaDAoIX19uYW1lX18QAg`);
           setError("Database index is missing or building...");
      } else { setError("Could not load your quests."); }
    } finally { setLoading(false); }
  };
  useEffect(() => { fetchQuests(); }, [user]);

  // Filter Quests
  const filteredQuests = useMemo(() => {
    let questStatus = 'open';
    if (filter === 'Completed') questStatus = 'completed';
    if (filter === 'Archived') questStatus = 'archived';
    if (filter === 'Active') { return quests.filter(q => q.status === 'open' || q.status === 'in-progress'); }
    return quests.filter(q => q.status === questStatus);
  }, [quests, filter]);

  // Calculate Stats
  const [stats, setStats] = useState({ pendingApps: 0, hiredCount: 0, posted: 0 });
  useEffect(() => {
      const fetchStats = async () => {
          if (!user) return;
          try {
              const postedCount = quests.length;
              const pendingAppsQuery = query( collection(db, "applications"), where("questGiverId", "==", user.uid), where("status", "==", "pending") );
              const pendingSnapshot = await getCountFromServer(pendingAppsQuery);
              const pendingCount = pendingSnapshot.data().count;
              const hiredQuestsQuery = query( collection(db, "quests"), where("questGiverId", "==", user.uid), where("status", "in", ["in-progress", "completed"]) );
              const hiredSnapshot = await getCountFromServer(hiredQuestsQuery);
              const hiredCount = hiredSnapshot.data().count;
              setStats({ pendingApps: pendingCount, hiredCount: hiredCount, posted: postedCount });
          } catch (error) { console.error("Error fetching stats:", error); setStats({ pendingApps: '?', hiredCount: '?', posted: quests.length }); }
      };
      fetchStats();
  }, [quests, user]);


  // Action Handlers
  const handleHireApplicant = async (questId, applicationId, applicantId) => {
    setActionMessage("Processing hiring...");
    try {
      const batch = writeBatch(db); const appRef = doc(db, "applications", applicationId); batch.update(appRef, { status: "hired" });
      const questRef = doc(db, "quests", questId); batch.update(questRef, { status: "in-progress", hiredApplicantId: applicantId });
      const otherAppsQuery = query( collection(db, "applications"), where("questId", "==", questId), where("status", "==", "pending") );
      const otherAppsSnapshot = await getDocs(otherAppsQuery); otherAppsSnapshot.forEach(appDoc => { if (appDoc.id !== applicationId) { batch.update(appDoc.ref, { status: "rejected" }); } });
      await batch.commit(); setActionMessage("Applicant hired successfully!"); fetchQuests();
    } catch (err) { console.error("Error hiring applicant:", err); setActionMessage("Error hiring applicant."); }
  };
  const handleRejectApplicant = async (applicationId) => {
    setActionMessage(`Rejecting application ${applicationId}...`);
    try {
      const appRef = doc(db, "applications", applicationId); await updateDoc(appRef, { status: "rejected" });
      setActionMessage("Applicant rejected."); fetchQuests();
    } catch (err) { console.error("Error rejecting applicant:", err); setActionMessage("Error rejecting applicant."); }
  };
  
  // --- REPLACED/FIXED FUNCTION ---
  const handleMarkComplete = async (questId, hiredApplicantId, hiredApplicationId) => {
    setActionMessage(`Completing quest ${questId}...`);
    
    // Check for missing IDs before starting the transaction
    if (hiredApplicantId && !hiredApplicationId) {
        console.warn("hiredApplicationId is missing. Quester/Application state may not be updated correctly.");
    }

    try {
      await runTransaction(db, async (transaction) => {
        
        // --- 1. DEFINE ALL REFERENCES ---
        const questRef = doc(db, "quests", questId);
        const questGiverRef = doc(db, "users", user.uid);
        let questerRef = null;
        let hiredAppRef = null;

        if (hiredApplicantId) {
          questerRef = doc(db, "users", hiredApplicantId);
        }
        if (hiredApplicationId) {
          hiredAppRef = doc(db, "applications", hiredApplicationId);
        }

        // --- 2. EXECUTE ALL READS FIRST ---
        const questSnap = await transaction.get(questRef);
        const giverSnap = await transaction.get(questGiverRef);
        
        let questerSnap = null;
        if (questerRef) {
          questerSnap = await transaction.get(questerRef);
        }
        
        // Optional: Read app to ensure it exists.
        if (hiredAppRef) {
          const appSnap = await transaction.get(hiredAppRef);
          if (!appSnap.exists()) {
            console.warn("Could not find Hired Application:", hiredApplicationId);
            hiredAppRef = null; // Don't try to update a non-existent doc
          }
        }

        // --- 3. VALIDATE AND PREPARE WRITES ---
        
        // Validate quest and giver
        if (!questSnap.exists() || questSnap.data().status !== 'in-progress') {
          throw new Error("Quest not in progress or does not exist.");
        }
        if (!giverSnap.exists()) {
          throw new Error("Giver profile not found!");
        }

        // Prepare Quest Giver Updates
        const giverData = giverSnap.data();
        const currentGivenCompleted = giverData.questsGivenCompleted || 0;
        const newGivenCompleted = currentGivenCompleted + 1;
        const giverUpdates = { questsGivenCompleted: increment(1) };

        if (newGivenCompleted === 3 && !giverData.unlockedAchievements?.includes('quest_giver_1')) {
          giverUpdates.unlockedAchievements = arrayUnion('quest_giver_1');
        }
        if (newGivenCompleted === 10 && !giverData.unlockedAchievements?.includes('quest_giver_2')) {
          giverUpdates.unlockedAchievements = arrayUnion('quest_giver_2');
        }

        // Prepare Quester (Hired Applicant) Updates
        let questerUpdates = null;
        if (questerSnap && questerSnap.exists()) {
          const questerData = questerSnap.data();
          const currentCompleted = questerData.questsCompleted || 0;
          const newCompleted = currentCompleted + 1;
          questerUpdates = { questsCompleted: increment(1) };
          
          if (newCompleted === 1 && !questerData.unlockedAchievements?.includes('first_quest_completed')) {
            questerUpdates.unlockedAchievements = arrayUnion('first_quest_completed');
          }
          if (newCompleted === 5 && !questerData.unlockedAchievements?.includes('seasoned_quester_1')) {
            questerUpdates.unlockedAchievements = arrayUnion('seasoned_quester_1');
          }
          if (newCompleted === 15 && !questerData.unlockedAchievements?.includes('seasoned_quester_2')) {
            questerUpdates.unlockedAchievements = arrayUnion('seasoned_quester_2');
          }
        } else if (hiredApplicantId) {
          console.warn("Could not find Quester profile:", hiredApplicantId);
        }

        // --- 4. EXECUTE ALL WRITES LAST ---
        
        // Write 1: Update the Quest
        transaction.update(questRef, { status: "completed", completedAt: serverTimestamp() });
        
        // Write 2: Update the Quest Giver
        transaction.update(questGiverRef, giverUpdates);
        
        // Write 3: Update the Hired Application (if found)
        if (hiredAppRef) {
          transaction.update(hiredAppRef, { status: "completed" });
        }
        
        // Write 4: Update the Quester (if found)
        if (questerRef && questerUpdates) {
          transaction.update(questerRef, questerUpdates);
        }
        
      }); // End Transaction
      
      setActionMessage("Quest marked as completed!");
      fetchQuests();
      
    } catch (err) {
      console.error("Error marking quest complete:", err);
      setActionMessage(`Error: ${err.message}.`);
    }
  };
  // --- END REPLACED FUNCTION ---
  
  const handleDeleteQuest = async (questId) => {
    if (!window.confirm("Delete this quest?")) { return; }
    setActionMessage(`Deleting quest ${questId}...`);
    try {
        const questRef = doc(db, "quests", questId); await deleteDoc(questRef);
        setActionMessage("Quest deleted."); fetchQuests();
    } catch (err) { console.error("Error deleting quest:", err); setActionMessage("Error deleting quest."); }
  };
  const handleRateQuester = async (questerId, ratingValue, applicationId) => {
    setActionMessage("Submitting rating...");
    try {
      await runTransaction(db, async (transaction) => {
        const questerRef = doc(db, "users", questerId); const applicationRef = doc(db, "applications", applicationId);
        const questerSnap = await transaction.get(questerRef); if (!questerSnap.exists()) { throw "Quester profile not found!"; }
        const questerData = questerSnap.data(); const currentScore = questerData.totalRatingScore || 0; const currentCount = questerData.numberOfRatings || 0;
        const newScore = currentScore + ratingValue; const newCount = currentCount + 1; const newAvg = newCount > 0 ? newScore / newCount : 0;
        const questerUpdates = { totalRatingScore: increment(ratingValue), numberOfRatings: increment(1) };
        if (newCount >= 10 && newAvg >= 4.8 && !questerData.unlockedAchievements?.includes('top_rated')) { questerUpdates.unlockedAchievements = arrayUnion('top_rated'); }
        transaction.update(questerRef, questerUpdates);
        transaction.update(applicationRef, { giverRating: ratingValue, giverRated: true });
      });
      setActionMessage("Rating submitted."); fetchQuests();
    } catch (err) { console.error("Error submitting rating:", err); setActionMessage("Error submitting rating."); }
  };

  if (!user) { return <div className="bq-container" style={{padding: "2rem"}}>Loading...</div>; }

  return (
    <div className="bq-container">
      <div className="my-quests-layout">
        <aside className="profile-sidebar">
           <img src={`https://ui-avatars.com/api/?name=${user.name}&background=random`} alt={user.name} className="profile-avatar"/>
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
          {!loading && filteredQuests.length === 0 && ( <p>You haven't posted any quests...</p> )}
          <div className="quests-list">
            {!loading && filteredQuests.map(quest => (
              <PostedQuestItem
                key={quest.id} quest={quest}
                onHireApplicant={handleHireApplicant}
                onRejectApplicant={handleRejectApplicant}
                onMarkComplete={handleMarkComplete}
                onDeleteQuest={handleDeleteQuest}
                onRateQuester={handleRateQuester}
              />
            ))}
          </div>
        </main>
      </div>
    </div>
  );
}