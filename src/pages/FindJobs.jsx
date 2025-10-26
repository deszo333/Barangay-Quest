import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../firebase';
import { collection, query, getDocs, where, orderBy } from 'firebase/firestore';
import QuestCard from '../components/QuestCard';
import "./FindJobs.css";

// --- Default filter values ---
const MAX_PRICE = 10000;
const DEFAULT_SORT = 'createdAt-desc';

export default function FindJobs() {
  const [allQuests, setAllQuests] = useState([]); // Master list
  const [loading, setLoading] = useState(true);

  // --- Filter States ---
  const [jobType, setJobType] = useState('All');
  const [price, setPrice] = useState(MAX_PRICE); // Max price
  const [rating, setRating] = useState(0); // 0 = Any
  const [sortBy, setSortBy] = useState(DEFAULT_SORT);

  // Fetch ALL quests from Firestore just once
  useEffect(() => {
    const fetchQuests = async () => {
      try {
        setLoading(true);
        const questsCollection = collection(db, "quests");
        const q = query(
          questsCollection, 
          where("status", "==", "open")
        );

        const querySnapshot = await getDocs(q);
        const questsData = querySnapshot.docs.map(doc => ({
          id: doc.id,
          ...doc.data()
        }));
        
        setAllQuests(questsData);

      } catch (err) {
        console.error("Error fetching quests:", err);
      } finally {
        setLoading(false);
      }
    };

    fetchQuests();
  }, []); // Empty array means run once on mount

  // This creates the list of quests to display
  const filteredQuests = useMemo(() => {
    let quests = [...allQuests];

    // 1. Filter by Job Type
    if (jobType !== 'All') {
      quests = quests.filter(q => q.workType === jobType);
    }

    // 2. Filter by Price (FIXED)
    // Now filters all jobs with a budget less than or equal to the price
    if (price < MAX_PRICE) {
      quests = quests.filter(q => Number(q.budgetAmount) <= price);
    }
    
    // 3. Filter by Rating (Once we have real ratings)
    // if (rating > 0) {
    //   quests = quests.filter(q => q.rating >= rating);
    // }

    // 4. Sort the results
    quests.sort((a, b) => {
      switch (sortBy) {
        case 'price-asc':
          return Number(a.budgetAmount) - Number(b.budgetAmount);
        case 'price-desc':
          return Number(b.budgetAmount) - Number(a.budgetAmount);
        case 'rating-desc':
          return (b.rating || 0) - (a.rating || 0);
        default: // createdAt-desc
          return (b.createdAt?.toDate() || 0) - (a.createdAt?.toDate() || 0);
      }
    });

    return quests;

  }, [allQuests, jobType, price, rating, sortBy]);

  // --- NEW: Function to reset all filters ---
  const handleResetFilters = () => {
    setJobType('All');
    setPrice(MAX_PRICE);
    setRating(0);
    setSortBy(DEFAULT_SORT);
  };

  return (
    <div className="bq-container">
      <h1>Find Quests</h1>
      <div className="find-quests-layout">
        
        {/* === Left Sidebar (Filters) === */}
        <aside className="filter-sidebar">
          
          {/* --- NEW: Reset Button --- */}
          <button 
            className="btn btn-secondary" 
            style={{width: '100%', background: 'var(--card)'}}
            onClick={handleResetFilters}
          >
            Reset All Filters
          </button>
          
          <div className="filter-group">
            {/* --- CHANGED Label --- */}
            <h3>Max Budget</h3>
            <label className="price-slider-label">
              <span>₱0</span>
              <span>₱{price === MAX_PRICE ? `${MAX_PRICE.toLocaleString()}+` : price.toLocaleString()}</span>
            </label>
            <input 
              type="range" 
              className="price-slider"
              min="0"
              max={MAX_PRICE}
              step="100"
              value={price}
              onChange={(e) => setPrice(Number(e.target.value))}
            />
          </div>
          
          <div className="filter-group">
            <h3>Rating</h3>
            <RatingFilter rating={rating} setRating={setRating} />
          </div>

          <div className="filter-group">
            <h3>Job Type</h3>
            <ul>
              <li><label>
                <input type="radio" name="jobType" value="All" 
                  checked={jobType === 'All'} onChange={(e) => setJobType(e.target.value)} />
                All
              </label></li>
              <li><label>
                <input type="radio" name="jobType" value="In Person"
                  checked={jobType === 'In Person'} onChange={(e) => setJobType(e.target.value)} />
                In Person
              </label></li>
              <li><label>
                <input type="radio" name="jobType" value="Online"
                  checked={jobType === 'Online'} onChange={(e) => setJobType(e.target.value)} />
                Online
              </label></li>
            </ul>
          </div>

          <div className="filter-group">
            <button className="btn btn-outline">Show Map</button>
            <div className="map-placeholder">(Map goes here)</div>
          </div>
        </aside>

        {/* === Right Panel (Results) === */}
        <main className="results-panel">
          <div className="results-header">
            <h2>Find Results ({filteredQuests.length})</h2>
            <select 
              className="form-select" 
              style={{width: '200px', background: 'var(--bg-2)'}} // Added bg
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value)}
            >
              <option value="createdAt-desc">Sort by: Newest</option>
              <option value="rating-desc">Sort by: Rating (High-Low)</option>
              <option value="price-desc">Sort by: Price (High-Low)</option>
              <option value="price-asc">Sort by: Price (Low-High)</option>
            </select>
          </div>

          {loading && <p>Loading quests...</p>}

          {!loading && filteredQuests.length === 0 && (
            <p>No quests found matching your criteria.</p>
          )}

          <div className="results-grid">
            {!loading && filteredQuests.map(quest => (
              <QuestCard key={quest.id} quest={quest} />
            ))}
          </div>
        </main>
      </div>
    </div>
  );
}

// --- Helper component for Star Rating Filter ---
function RatingFilter({ rating, setRating }) {
  return (
    <div className="rating-group">
      {[1, 2, 3, 4, 5].map(star => (
        <span 
          key={star} 
          className={`star ${rating >= star ? 'active' : ''}`}
          onClick={() => setRating(star === rating ? 0 : star)} // Click again to clear
        >
          ★
        </span>
      ))}
      <span 
        style={{fontSize: '0.9rem', marginLeft: '0.5rem', cursor: 'pointer'}}
        onClick={() => setRating(0)}
      >
        (Any)
      </span>
    </div>
  );
}