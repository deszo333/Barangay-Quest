import React, { useState, useEffect } from 'react';
import { useParams, useOutletContext } from 'react-router-dom';
import { db } from '../firebase';
import { doc, getDoc, collection, addDoc, serverTimestamp, query, where, getDocs, limit } from 'firebase/firestore';
import "../pages/Home.css"; // For button styles
import "./MyApplications.css"; // Borrow sidebar styles for potential future use

// Helper to get user
function useUser() {
  return useOutletContext();
}

// Re-use formatPrice helper
function formatPrice(type, amount) {
  const num = Number(amount).toFixed(2);
  if (type === 'Hourly Rate') { return `₱${num} / hour`; }
  return `₱${num} (Fixed)`;
}

// --- ADDED MISSING formatDate HELPER ---
function formatDate(timestamp) {
  if (!timestamp) return "";
  const seconds = Math.floor((new Date() - timestamp.toDate()) / 1000);
  let interval = seconds / 86400; // Days
  if (interval > 1) return timestamp.toDate().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }); // Show date if > 1 day
  interval = seconds / 3600; // Hours
  if (interval > 1) return Math.floor(interval) + " hours ago";
  interval = seconds / 60; // Minutes
  if (interval > 1) return Math.floor(interval) + " minutes ago";
  return "Just now";
}

export default function QuestDetailPage() {
  const { id } = useParams();
  const { user } = useUser();
  const [quest, setQuest] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [applied, setApplied] = useState(false);
  const [applyLoading, setApplyLoading] = useState(false);

  // Fetch Quest Details
  useEffect(() => {
    const fetchQuest = async () => {
      setError(null);
      setLoading(true);
      try {
        const questRef = doc(db, "quests", id);
        const questSnap = await getDoc(questRef);

        if (questSnap.exists()) {
          setQuest({ id: questSnap.id, ...questSnap.data() });
        } else {
          setError("Quest not found.");
        }
      } catch (err) {
        console.error("Error fetching quest:", err);
        setError("Failed to load quest details.");
      } finally {
        setLoading(false);
      }
    };

    if (id) {
      fetchQuest();
    }
  }, [id]);

  // Check if user has already applied
  useEffect(() => {
    setError(null);
    setApplied(false);

    const checkIfApplied = async () => {
      if (!user || !quest || user.uid === quest.questGiverId) return;

      const appsRef = collection(db, "applications");
      const q = query(
        appsRef,
        where("questId", "==", quest.id),
        where("applicantId", "==", user.uid),
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
  }, [user, quest]);


  // Apply Function
  const handleApply = async () => {
    setError(null);
    if (!user) { setError("Please log in to apply."); return; }
    if (!quest) { setError("Quest data not loaded."); return; }
    if (user.uid === quest.questGiverId) { setError("You cannot apply to your own quest."); return; }
    if (applied) return;
    if (quest.status !== 'open') { setError("This quest is no longer accepting applications."); return; }

    setApplyLoading(true);

    try {
      await addDoc(collection(db, "applications"), {
        questId: quest.id,
        questTitle: quest.title,
        questGiverId: quest.questGiverId,
        applicantId: user.uid,
        applicantName: user.name,
        status: "pending",
        appliedAt: serverTimestamp()
      });
      setApplied(true);
    } catch (err) {
      console.error("Error applying:", err);
      setError("Failed to apply. Please try again.");
    } finally {
      setApplyLoading(false);
    }
  };


  if (loading) {
    return <div className="bq-container" style={{padding: "2rem"}}>Loading quest...</div>;
  }

  if (error && !quest) {
      return <div className="bq-container" style={{padding: "2rem", color: '#ff8a8a'}}>{error}</div>;
  }

  if (!quest) {
      return <div className="bq-container" style={{padding: "2rem"}}>Quest not found.</div>;
  }

  const canApply = user && quest.status === 'open' && user.uid !== quest.questGiverId;

  return (
    <div className="bq-container" style={{padding: "2rem", display: 'grid', gap: '1rem'}}>
      <h1>{quest.title}</h1>
      <p style={{marginTop: '-1rem', color: 'var(--muted)', fontSize: '1.1rem'}}>
        Posted by {quest.questGiverName} • {formatDate(quest.createdAt)}
      </p>

      {/* --- UPDATED: This is now a 2-column grid that stacks cleanly --- */}
      <div style={{ 
        display: 'grid', 
        gridTemplateColumns: 'repeat(auto-fit, minmax(250px, 1fr))', 
        gap: '1rem',
        background: 'var(--bg-2)',
        padding: '1.5rem',
        borderRadius: 'var(--radius)',
        border: '1px solid var(--card)'
      }}>
        <div><strong>Category:</strong><br/> {quest.category}</div>
        <div><strong>Status:</strong><br/> <span className={`app-status ${quest.status}`} style={{textTransform: 'capitalize'}}>{quest.status}</span></div>
        <div><strong>Location:</strong><br/> {quest.location?.address || quest.workType}</div>
        <div><strong>Schedule:</strong><br/> {quest.schedule}</div>
        <div><strong>Engagement:</strong><br/> {quest.engagement || 'One-Time'}</div>
        <div><strong>Budget:</strong><br/> {formatPrice(quest.budgetType, quest.budgetAmount)}</div>
      </div>
      {/* --- END UPDATED --- */}


      {quest.imageUrl && (
        <img
          src={quest.imageUrl}
          alt={quest.title}
          style={{maxWidth: '400px', borderRadius: '10px', marginTop: '1rem'}}
        />
      )}

      <h3 style={{marginTop: '1rem', marginBottom: '0.5rem'}}>Description:</h3>
      <p style={{whiteSpace: 'pre-wrap', lineHeight: 1.6}}>{quest.description}</p>

      {canApply && (
        <button
          className="btn btn-accent"
          style={{marginTop: '2rem', justifySelf: 'start'}}
          onClick={handleApply}
          disabled={applyLoading || applied}
        >
          {applyLoading ? "Applying..." : (applied ? "Application Submitted" : "Apply Now")}
        </button>
      )}

      {error && <p style={{ color: "#ff8a8a", marginTop: '1rem' }}>{error}</p>}

       {quest.status !== 'open' && (
           <p style={{ marginTop: '2rem', color: 'var(--muted)', background: 'var(--bg-2)', padding: '1rem', borderRadius: 'var(--radius)', border: '1px solid var(--card)'}}>
               This quest is currently {quest.status} and is not accepting new applications.
           </p>
       )}
    </div>
  );
}