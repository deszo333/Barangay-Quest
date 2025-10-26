import React, { useState, useMemo } from 'react';
import { useOutletContext } from 'react-router-dom';
import "./AchievementsPage.css"; // Import the CSS

// --- Define All Possible Achievements ---
const ALL_ACHIEVEMENTS = [
  { id: 'quest_initiator', name: 'Quest Initiator', description: 'Post your first quest.', icon: '✍️', maxProgress: 1 },
  { id: 'first_quest_completed', name: 'First Step', description: 'Complete your first quest as a Quester.', icon: '👟', maxProgress: 1 },
  { id: 'seasoned_quester_1', name: 'Seasoned Quester I', description: 'Complete 5 quests.', icon: '⭐', maxProgress: 5 },
  { id: 'seasoned_quester_2', name: 'Seasoned Quester II', description: 'Complete 15 quests.', icon: '🌟', maxProgress: 15 },
  { id: 'quest_giver_1', name: 'Quest Giver I', description: 'Successfully have 3 posted quests completed.', icon: '📜', maxProgress: 3 },
  { id: 'quest_giver_2', name: 'Quest Giver II', description: 'Successfully have 10 posted quests completed.', icon: ' M', maxProgress: 10 },
  { id: 'top_rated', name: 'Top Rated', description: 'Achieve an average rating of 4.8+ stars (min. 10 ratings).', icon: '🏆', maxProgress: 1 },
];

// Helper to get user context
function useUser() {
  return useOutletContext();
}

// --- Achievement Card Component ---
function AchievementCard({ achievement, isUnlocked, user }) {
    let currentProgress = 0;
    const maxProgress = achievement.maxProgress || 1;
    const safeUser = user || {}; // Use empty object if user is null during initial render

    if (isUnlocked) {
        currentProgress = maxProgress;
    } else {
        switch (achievement.id) {
            case 'seasoned_quester_1': case 'seasoned_quester_2': currentProgress = safeUser.questsCompleted || 0; break;
            case 'quest_giver_1': case 'quest_giver_2': currentProgress = safeUser.questsGivenCompleted || 0; break;
            default: currentProgress = 0;
        }
    }
    const displayProgress = Math.min(currentProgress, maxProgress);
    const progressPercent = maxProgress === 0 ? 0 : Math.min(100, (displayProgress / maxProgress) * 100);

    return (
        <div className={`achievement-card ${isUnlocked ? 'unlocked' : ''}`} title={achievement.description}>
            <div className="achievement-icon">{achievement.icon}</div>
            <div className="achievement-details">
                <h3>{achievement.name}</h3>
                <p>{achievement.description}</p>
                {maxProgress > 1 && (
                    <>
                        <div className="progress-bar-container"> <div className="progress-bar-fill" style={{ width: `${progressPercent}%` }}></div> </div>
                        <p className="progress-text">{displayProgress} / {maxProgress}</p>
                    </>
                )}
                 {!isUnlocked && maxProgress <= 1 && <p className="locked-text">(Locked)</p>}
            </div>
        </div>
    );
}


// --- Main Page Component ---
export default function AchievementsPage() {
  const { user } = useUser(); // Hook Call 1: useOutletContext
  const [activeTab, setActiveTab] = useState('Unlocked'); // Hook Call 2: useState

  // --- MOVED HOOKS BEFORE EARLY RETURN ---
  // Hook Call 3: useMemo - Calculate unlocked IDs safely, defaulting to empty array if user/achievements don't exist yet
  const unlockedIds = useMemo(() => new Set(user?.unlockedAchievements || []), [user?.unlockedAchievements]);
  // Hook Call 4: useMemo - Filter unlocked achievements
  const unlockedAchievements = useMemo(() => ALL_ACHIEVEMENTS.filter(ach => unlockedIds.has(ach.id)), [unlockedIds]);
  // Hook Call 5: useMemo - Filter locked achievements
  const lockedAchievements = useMemo(() => ALL_ACHIEVEMENTS.filter(ach => !unlockedIds.has(ach.id)), [unlockedIds]);
  // --- END MOVED HOOKS ---

  // Now the early return check is safe, happens after all hooks
  if (!user) {
    // Return loading state or null while user data is being fetched
    return <div className="bq-container" style={{ padding: "2rem" }}>Loading user achievements...</div>;
  }

  // Determine which list to display based on the active tab
  const achievementsToDisplay = activeTab === 'Unlocked' ? unlockedAchievements : lockedAchievements;

  return (
    <div className="bq-container achievements-page">
      <div className="achievements-header">
          <h1>Your Achievements</h1>
          {/* Tabs */}
          <div className="achievements-tabs">
            <button
              className={`achievements-tab-button ${activeTab === 'Unlocked' ? 'active' : ''}`}
              onClick={() => setActiveTab('Unlocked')}
            >
              Unlocked ({unlockedAchievements.length})
            </button>
            <button
              className={`achievements-tab-button ${activeTab === 'Locked' ? 'active' : ''}`}
              onClick={() => setActiveTab('Locked')}
            >
              Locked ({lockedAchievements.length})
            </button>
          </div>
      </div>


      {/* Grid */}
      {achievementsToDisplay.length === 0 ? (
          <p style={{marginTop: '2rem', textAlign: 'center'}}>
              {activeTab === 'Unlocked' ? "You haven't unlocked any achievements yet. Keep questing!" : "You've unlocked all available achievements!"}
          </p>
      ) : (
        <div className="achievements-grid">
            {achievementsToDisplay.map(ach => (
            <AchievementCard
                key={ach.id}
                achievement={ach}
                isUnlocked={unlockedIds.has(ach.id)} // Pass boolean directly
                user={user} // Pass full user object
            />
            ))}
            {/* Sidebar elements can be added here if needed */}
        </div>
      )}
    </div>
  );
}