import React, { useState, useEffect } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { db, auth } from '../firebase';
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
// --- NEW: Import updateDoc, doc, and increment ---
import { doc, updateDoc, getDoc, increment } from "firebase/firestore";
import "./Auth.css"; // Reuse auth form styles
import "../pages/Home.css"; // For button styles
import "./MyApplications.css"; // Contains .profile-avatar
import "./PostJob.css"; // Contains .form-file-input


function useUser() {
  return useOutletContext();
}

export default function ProfilePage() { // <-- Renamed component
  const { user, setUser } = useUser(); // Get user and the function to update global state
  const navigate = useNavigate();
  const [file, setFile] = useState(null);
  const [previewUrl, setPreviewUrl] = useState(null);
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [currentAvatarUrl, setCurrentAvatarUrl] = useState(null);

  useEffect(() => {
    if (user?.avatarUrl) {
      setCurrentAvatarUrl(user.avatarUrl);
    } else if (user?.name) {
      setCurrentAvatarUrl(`https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&size=128`);
    } else {
        setCurrentAvatarUrl('https://via.placeholder.com/128');
    }
  }, [user]);

  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    if (selectedFile && selectedFile.type.startsWith('image/')) {
      setFile(selectedFile);
      setPreviewUrl(URL.createObjectURL(selectedFile));
      setMessage(""); 
    } else {
      setFile(null); 
      setPreviewUrl(null); 
      setMessage("Please select a valid image file (jpg, png, webp).");
    }
  };

  const handleUpload = async () => {
    if (!file) {
      setMessage("Please select a file first.");
      return;
    }
    if (!user) {
      setMessage("Error: User not found. Please log in again.");
      return;
    }

    setLoading(true); 
    setMessage("Uploading picture...");

    try {
      const storage = getStorage();
      const fileExtension = file.name.split('.').pop();
      const filePath = `profile_pictures/${user.uid}.${fileExtension}`;
      const storageRef = ref(storage, filePath);

      const snapshot = await uploadBytes(storageRef, file);
      const downloadURL = await getDownloadURL(snapshot.ref);

      const userDocRef = doc(db, "users", user.uid);
      await updateDoc(userDocRef, {
        avatarUrl: downloadURL,
      });

      setUser(prevUser => ({ ...prevUser, avatarUrl: downloadURL }));
      setMessage("✅ Profile picture updated successfully!");
      setCurrentAvatarUrl(downloadURL); 
      setFile(null);
      setPreviewUrl(null); 
      if (previewUrl) { URL.revokeObjectURL(previewUrl); }

    } catch (err) {
      console.error("Upload error:", err);
      setMessage(`Upload failed: ${err.message}. Please try again.`);
    } finally {
      setLoading(false);
    }
  };
  
  // --- NEW: Function to add demo funds ---
  const addDemoFunds = async () => {
    setLoading(true);
    setMessage("Adding funds...");
    const userRef = doc(db, "users", user.uid);
    try {
      // Use increment to safely add to the wallet balance
      await updateDoc(userRef, {
        walletBalance: increment(10000)
      });
      // Manually update the local user state from context so it updates instantly
      setUser(prevUser => ({ ...prevUser, walletBalance: (prevUser.walletBalance || 0) + 10000 }));
      setMessage("✅ ₱10,000 in demo credits added!");
    } catch (err) {
      console.error("Error adding funds:", err);
      setMessage("Error adding funds. Please try again.");
    }
    setLoading(false);
  };

  if (!user) {
    return <div className="bq-container" style={{ padding: "2rem" }}>Loading settings...</div>;
  }

  return (
    <div className="bq-container" style={{ padding: "2rem 0" }}>
      {/* Reuse auth form container style for layout consistency */}
      <div className="auth-form-container" style={{ maxWidth: '600px', margin: 'auto' }}>
        
        {/* --- NEW: Wallet Section --- */}
        <div className="wallet-section" style={{ marginBottom: '2rem', paddingBottom: '2rem', borderBottom: '1px solid var(--card)' }}>
          <h1>My Wallet</h1>
          <p style={{ color: 'var(--muted)', fontSize: '1.1rem', margin: 0 }}>Current Balance</p>
          <p style={{
            color: 'var(--status-completed)',
            fontSize: '2.5rem',
            fontWeight: '700',
            margin: '0.5rem 0 1.5rem'
          }}>
            ₱{user.walletBalance?.toFixed(2) || '0.00'}
          </p>
          <button
            className="btn btn-secondary"
            onClick={addDemoFunds}
            disabled={loading}
          >
            {loading ? "Processing..." : "Add ₱10,000 (Demo)"}
          </button>
        </div>
        {/* --- END: Wallet Section --- */}

        <h1>Profile Settings</h1>
        
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <img
            src={previewUrl || currentAvatarUrl || 'https://via.placeholder.com/128'}
            alt="Profile Avatar Preview"
            className="profile-avatar"
            style={{ width: '128px', height: '128px', border: '2px solid var(--card)' }}
          />
        </div>

        <div className="auth-form">
          <div className="auth-field">
            <label htmlFor="avatarFile">Upload New Profile Picture</label>
            <input
              type="file"
              id="avatarFile"
              className="form-file-input"
              accept="image/png, image/jpeg, image/webp"
              onChange={handleFileChange}
            />
          </div>

          {message && <p style={{ color: message.startsWith('✅') ? 'var(--status-completed)' : '#ff8a8a', marginTop: '1rem', textAlign: 'center' }}>{message}</p>}

          <button
            className="btn btn-accent btn-auth"
            onClick={handleUpload}
            disabled={!file || loading}
            style={{ marginTop: '1rem' }}
          >
            {loading ? "Uploading..." : "Save Profile Picture"}
          </button>
        </div>
      </div>
    </div>
  );
}