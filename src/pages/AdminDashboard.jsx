import React, { useState, useEffect } from 'react';
import { db } from '../firebase';
import { collection, query, where, getDocs, doc, updateDoc } from 'firebase/firestore';
import "./Auth.css"; // Reuse the styles
import "../pages/Home.css"; // For button styles

export default function AdminDashboard() {
  const [pendingUsers, setPendingUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [message, setMessage] = useState("");

  // Function to fetch all pending users
  const fetchPendingUsers = async () => {
    try {
      setLoading(true);
      setMessage("");
      const usersCollection = collection(db, 'users');
      const q = query(usersCollection, where("status", "==", "pending"));
      
      const querySnapshot = await getDocs(q);
      const usersList = querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setPendingUsers(usersList);

    } catch (err) {
      console.error(err);
      setMessage("Error fetching users.");
    } finally {
      setLoading(false);
    }
  };

  // Run the fetch function when the page loads
  useEffect(() => {
    fetchPendingUsers();
  }, []);

  // Function to approve a user
  const handleApprove = async (userId) => {
    try {
      setMessage(`Approving user ${userId}...`);
      const userDocRef = doc(db, "users", userId);
      await updateDoc(userDocRef, {
        status: "approved"
      });

      // Refresh the list after approval
      fetchPendingUsers();
      setMessage("User approved successfully!");

    } catch (err) {
      console.error(err);
      setMessage("Error approving user.");
    }
  };

  return (
    <div className="bq-container" style={{padding: "2rem 0", minHeight: '60vh'}}>
      <h1>Admin Dashboard</h1>
      <p style={{color: 'var(--muted)', fontSize: '1.1rem'}}>Pending User Registrations</p>
      
      {loading && <p>Loading users...</p>}
      {message && <p>{message}</p>}

      <div className="pending-users-list" style={{display: 'grid', gap: '1.25rem', marginTop: '2rem'}}>
        {pendingUsers.length === 0 && !loading && (
          <div className="card" style={{padding: '1.5rem', textAlign: 'center', background: 'var(--bg-2)'}}>
            <p>No pending users found.</p>
          </div>
        )}

        {pendingUsers.map(user => (
          <div 
            key={user.id} 
            className="card" 
            style={{
              padding: '1.5rem', 
              background: 'var(--bg-2)', 
              border: '1px solid #20455b'
            }}
          >
            <div style={{display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: '1rem'}}>
              
              {/* === Left Side: User Details === */}
              <div>
                <h3 style={{margin: '0 0 0.75rem 0', color: 'var(--white)', fontSize: '1.4rem'}}>
                  {user.name || 'No Name Provided'}
                </h3>
                <ul style={{listStyle: 'none', padding: 0, margin: 0, color: 'var(--muted)', display: 'grid', gap: '0.5rem'}}>
                  
                  {/* --- Phone (Most Important) --- */}
                  <li style={{display: 'flex', alignItems: 'center', gap: '0.5rem'}}>
                    <strong style={{minWidth: '100px'}}>VERIFY PHONE:</strong>
                    <span style={{color: 'var(--accent)', fontWeight: 'bold', fontSize: '1.1rem'}}>
                      {user.phone || 'No phone provided'}
                    </span>
                  </li>

                  {/* --- Email --- */}
                  <li>
                    <strong style={{minWidth: '100px'}}>Email:</strong>
                    <span>{user.email || 'No email provided'}</span>
                  </li>

                  {/* --- "OK to call?" line removed --- */}

                </ul>
              </div>

              {/* === Right Side: Action Buttons === */}
              <div style={{display: 'flex', gap: '0.75rem'}}>
                <button 
                  className="btn btn-accent"
                  onClick={() => handleApprove(user.id)}
                  style={{padding: '0.75rem 1.25rem'}}
                >
                  Approve
                </button>
              </div>

            </div>
          </div>
        ))}
      </div>
    </div>
  );
}