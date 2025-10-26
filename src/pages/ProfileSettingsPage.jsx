import React, { useState, useEffect } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { db, auth } from '../firebase'; // Import auth for user ID
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { doc, updateDoc, getDoc } from "firebase/firestore";
import "./Auth.css"; // Reuse auth form styles
import "../pages/Home.css"; // For button styles
// Import styles needed for profile avatar display
import "./MyApplications.css"; // Contains .profile-avatar
// Import styles for file input if needed (assuming it's in PostJob.css)
import "./PostJob.css"; // Contains .form-file-input


function useUser() {
  return useOutletContext();
}

export default function ProfileSettingsPage() {
  const { user, setUser } = useUser(); // Get user and the function to update global state
  const navigate = useNavigate();
  const [file, setFile] = useState(null); // State for the selected file
  const [previewUrl, setPreviewUrl] = useState(null); // State for image preview
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState("");
  const [currentAvatarUrl, setCurrentAvatarUrl] = useState(null); // State for current avatar display URL

  // Effect to set the initial avatar URL for display
  useEffect(() => {
    if (user?.avatarUrl) {
      setCurrentAvatarUrl(user.avatarUrl); // Use uploaded avatar if available
    } else if (user?.name) {
      // Generate initial placeholder if no avatar exists, using user's name
      setCurrentAvatarUrl(`https://ui-avatars.com/api/?name=${encodeURIComponent(user.name)}&background=random&size=128`);
    } else {
        setCurrentAvatarUrl('https://via.placeholder.com/128'); // Fallback placeholder
    }
  }, [user]); // Re-run if user object changes (e.g., after upload)

  // Handle file selection from the input
  const handleFileChange = (e) => {
    const selectedFile = e.target.files[0];
    // Basic validation for image type
    if (selectedFile && selectedFile.type.startsWith('image/')) {
      setFile(selectedFile);
      // Create a temporary local URL for immediate preview
      setPreviewUrl(URL.createObjectURL(selectedFile));
      setMessage(""); // Clear any previous messages
    } else {
      setFile(null); // Reset file state if invalid
      setPreviewUrl(null); // Clear preview
      setMessage("Please select a valid image file (jpg, png, webp).");
    }
  };

  // Handle the upload process to Firebase Storage and Firestore update
  const handleUpload = async () => {
    if (!file) {
      setMessage("Please select a file first.");
      return;
    }
    if (!user) {
      setMessage("Error: User not found. Please log in again.");
      return; // Should not happen if page is protected by ApprovedRoute
    }

    setLoading(true); // Disable button, show loading state
    setMessage("Uploading picture...");

    try {
      const storage = getStorage(); // Get Firebase Storage instance
      // Define storage path (e.g., profile_pictures/userId.jpg)
      // Using user.uid ensures a unique path per user and overwrites previous picture
      const fileExtension = file.name.split('.').pop(); // Get file extension
      const filePath = `profile_pictures/${user.uid}.${fileExtension}`;
      const storageRef = ref(storage, filePath);

      // 1. Upload the file to Firebase Storage
      console.log(`Uploading to: ${filePath}`);
      const snapshot = await uploadBytes(storageRef, file);
      console.log("Upload successful:", snapshot);

      // 2. Get the public download URL for the uploaded file
      const downloadURL = await getDownloadURL(snapshot.ref);
      console.log("Download URL:", downloadURL);

      // 3. Update the user's document in Firestore with the new avatar URL
      const userDocRef = doc(db, "users", user.uid);
      await updateDoc(userDocRef, {
        avatarUrl: downloadURL, // Set the avatarUrl field
      });
      console.log("Firestore document updated with new avatarUrl.");

      // 4. Update the global user state (passed via context) for immediate UI feedback across the app
      setUser(prevUser => ({ ...prevUser, avatarUrl: downloadURL }));

      setMessage("✅ Profile picture updated successfully!");
      setCurrentAvatarUrl(downloadURL); // Update the displayed avatar immediately
      setFile(null); // Clear file input state after successful upload
      setPreviewUrl(null); // Clear the temporary preview URL
      // Optionally revoke the object URL to free memory
      if (previewUrl) { URL.revokeObjectURL(previewUrl); }


    } catch (err) {
      console.error("Upload error:", err);
      setMessage(`Upload failed: ${err.message}. Please try again.`); // Show error message to user
    } finally {
      setLoading(false); // Re-enable button
    }
  };

  // Fallback display if user data isn't loaded yet
  if (!user) {
    return <div className="bq-container" style={{ padding: "2rem" }}>Loading settings...</div>;
  }

  // Render the settings page UI
  return (
    <div className="bq-container" style={{ padding: "2rem 0" }}>
      {/* Reuse auth form container style for layout consistency */}
      <div className="auth-form-container" style={{ maxWidth: '600px', margin: 'auto' }}>
        <h1>Profile Settings</h1>

        {/* Display Current Avatar or the selected Preview */}
        <div style={{ textAlign: 'center', marginBottom: '1.5rem' }}>
          <img
            // Show the temporary preview URL if a file is selected, otherwise show the current avatar
            src={previewUrl || currentAvatarUrl || 'https://via.placeholder.com/128'} // Added final fallback
            alt="Profile Avatar Preview"
            className="profile-avatar" // Reuse style from MyApplications.css
            style={{ width: '128px', height: '128px', border: '2px solid var(--card)' }} // Adjusted size and added border
          />
        </div>

        {/* Reuse auth-form for styling the input and button */}
        <div className="auth-form">
          <div className="auth-field">
            <label htmlFor="avatarFile">Upload New Profile Picture</label>
            <input
              type="file"
              id="avatarFile"
              className="form-file-input" // Reuse style from PostJob.css
              accept="image/png, image/jpeg, image/webp" // Specify accepted image types
              onChange={handleFileChange} // Call handler on file selection
            />
          </div>

          {/* Display feedback messages (success or error) */}
          {message && <p style={{ color: message.startsWith('✅') ? 'var(--status-completed)' : '#ff8a8a', marginTop: '1rem', textAlign: 'center' }}>{message}</p>}

          {/* Upload Button */}
          <button
            className="btn btn-accent btn-auth" // Reuse button style
            onClick={handleUpload}
            disabled={!file || loading} // Disable if no file selected or during upload
            style={{ marginTop: '1rem' }}
          >
            {loading ? "Uploading..." : "Save Profile Picture"}
          </button>
        </div>
      </div>
    </div>
  );
}