import React, { useState } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { db } from '../firebase';
// Import transaction, doc, getDoc, updateDoc, increment, arrayUnion, collection, serverTimestamp
import {
    collection, addDoc, serverTimestamp, doc, updateDoc, increment,
    runTransaction, getDoc, arrayUnion
} from 'firebase/firestore';
import { getStorage, ref, uploadBytes, getDownloadURL } from "firebase/storage";
import { GoogleMap, useLoadScript, MarkerF } from '@react-google-maps/api';
import "./PostJob.css";

// API Key (Replace with yours)
const GOOGLE_MAPS_API_KEY = "AIzaSyDBE8OWqa1pnm-6nyq4lxPK8TVlv_q7kFs";

// Map settings
const mapLibraries = ["places", "geocoding"];
const mapCenter = { lat: 14.5995, lng: 120.9842 };
const mapContainerStyle = { width: '100%', height: '400px', borderRadius: '10px', border: '1px solid #20455b' };

// Hook to get user
function useUser() {
  return useOutletContext();
}

// Stepper Component
function Stepper({ currentStep }) {
  return (
    <div className="stepper">
      <div className={`step ${currentStep === 1 ? 'active' : ''}`}> <span className="step-number">1</span> <span className="step-label">Details</span> </div>
      <div className={`step ${currentStep === 2 ? 'active' : ''}`}> <span className="step-number">2</span> <span className="step-label">Review & Submit</span> </div>
    </div>
  );
}

export default function PostJob() {
  const { user } = useUser();
  const navigate = useNavigate();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [step, setStep] = useState(1);
  const [marker, setMarker] = useState(null);
  const [locationAddress, setLocationAddress] = useState("");
  const [imageFile, setImageFile] = useState(null);

  const [formData, setFormData] = useState({
    title: '', category: '', workType: 'In Person', schedule: '',
    budgetType: 'Fixed Rate', budgetAmount: '', description: '', agreeToTerms: false,
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prevData => ({ ...prevData, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleFileChange = (e) => { if (e.target.files[0]) { setImageFile(e.target.files[0]); } };

  const handleGoToReview = (e) => {
    e.preventDefault();
    if (!formData.agreeToTerms) { setError("You must agree to the terms of service."); return; }
    if (formData.workType === 'In Person' && !marker) { setError("Please pin the job location on the map."); return; }
    setError(null); setStep(2);
  };

  // Submit Function with Achievement Check
  const handleSubmitToFirebase = async () => {
    if (!user) { setError("User not found. Please log in again."); return; }

    setLoading(true); setError(null);
    let imageUrl = null;

    try {
      // Step 1: Upload image if exists (outside transaction)
      if (imageFile) {
        console.log("Uploading image...");
        const storage = getStorage();
        const imagePath = `quest_images/${user.uid}/${Date.now()}_${imageFile.name}`;
        const storageRef = ref(storage, imagePath);
        const snapshot = await uploadBytes(storageRef, imageFile);
        imageUrl = await getDownloadURL(snapshot.ref);
        console.log("Image upload complete:", imageUrl);
      } else {
        console.log("No image to upload.");
      }

      // Step 2: Use a transaction to save quest and update user atomically
      console.log("Starting Firestore transaction...");
      await runTransaction(db, async (transaction) => {
        const userRef = doc(db, "users", user.uid);
        // Get user data *within* the transaction to ensure consistency
        console.log("Getting user data within transaction...");
        const userSnap = await transaction.get(userRef);

        if (!userSnap.exists()) {
          throw new Error("User profile not found!");
        }

        const userData = userSnap.data();
        const currentPostedCount = userData.questsPosted || 0;
        const newPostedCount = currentPostedCount + 1;
        console.log(`Current questsPosted: ${currentPostedCount}, New count: ${newPostedCount}`);

        // A. Define user updates
        const userUpdates = {
          questsPosted: increment(1)
        };

        // B. Check for "Quest Initiator" achievement
        const achievementId = 'quest_initiator'; // Consistent ID
        const alreadyHasAchievement = userData.unlockedAchievements?.includes(achievementId);
        console.log(`Checking achievement '${achievementId}'. Already has: ${alreadyHasAchievement}`);

        if (newPostedCount === 1 && !alreadyHasAchievement) {
           console.log(`AWARDING achievement '${achievementId}'!`);
           // Use arrayUnion to safely add the achievement ID to the array
           userUpdates.unlockedAchievements = arrayUnion(achievementId);
        }
        // Add checks for other posting achievements (e.g., 5, 15 posts) here if needed

        // C. Update the user document within the transaction
        console.log("Updating user document:", userUpdates);
        transaction.update(userRef, userUpdates);

        // D. Create the new quest document (generate ref before using in transaction)
        const newQuestRef = doc(collection(db, "quests")); // Get a reference for the new quest
        console.log("Creating new quest document:", newQuestRef.id);
        transaction.set(newQuestRef, {
            ...formData, // Spread existing form data
            location: { // Structure location data
                lat: marker ? marker.lat : null,
                lng: marker ? marker.lng : null,
                address: locationAddress || (formData.workType === 'Online' ? 'Online' : 'Location Not Pinned') // Ensure address exists
             },
            imageUrl: imageUrl, // Include image URL (null if no image)
            questGiverId: user.uid, // Link to the user who posted
            questGiverName: user.name, // Store name for easier display
            status: 'open', // Initial status
            createdAt: serverTimestamp() // Add server timestamp
        });
        console.log("Transaction operations queued.");
      }); // End Transaction
      console.log("Transaction committed successfully.");

      setLoading(false);
      navigate("/my-quests"); // Redirect after successful post

    } catch (err) {
      console.error("Error posting job:", err);
      setError(`Error during submission: ${err.message}`); // Show specific error
      setLoading(false);
    }
  };

  // --- Render Logic ---
  return (
    <div className="bq-container">
      <div className="post-job-layout">
        <div className="post-job-main">
          <h1>POST A JOB</h1>
          <Stepper currentStep={step} />

          {/* Step 1: Details Form */}
          {step === 1 && (
            <form className="post-job-form" onSubmit={handleGoToReview}>
              {/* Job Title */}
              <div className="form-group"> <label htmlFor="title" className="required">Job Title</label> <input type="text" id="title" name="title" className="form-input" value={formData.title} onChange={handleChange} required /> </div>
              {/* Category */}
              <div className="form-group"> <label htmlFor="category" className="required">Category</label> <input type="text" id="category" name="category" className="form-input" placeholder="e.g., Home Repair, Tutoring" value={formData.category} onChange={handleChange} required /> </div>
              {/* Work Type */}
              <div className="form-group"> <label>Work Type</label> <div className="form-toggle"> <input type="radio" id="workTypeInPerson" name="workType" value="In Person" checked={formData.workType === 'In Person'} onChange={handleChange}/> <label htmlFor="workTypeInPerson">In Person</label> <input type="radio" id="workTypeOnline" name="workType" value="Online" checked={formData.workType === 'Online'} onChange={handleChange}/> <label htmlFor="workTypeOnline">Online</label> </div> </div>
              {/* Location Map (Conditional) */}
              {formData.workType === 'In Person' && ( <div className="form-group"> <label htmlFor="location" className="required">Pin Job Location</label> <p style={{color: 'var(--muted)', margin: '-5px 0 10px'}}>Click map to drop pin.</p> <MapPicker setMarker={setMarker} setLocationAddress={setLocationAddress}/> {locationAddress && ( <input type="text" className="form-input" value={locationAddress} readOnly style={{marginTop: '10px', background: 'var(--bg)'}} /> )} </div> )}
              {/* Schedule & Budget Grid */}
              <div className="form-grid-2">
                {/* Schedule */}
                <div className="form-group"> <label htmlFor="schedule">Schedule</label> <input type="text" id="schedule" name="schedule" className="form-input" placeholder="e.g., Weekends" value={formData.schedule} onChange={handleChange} /> </div>
                {/* Budget */}
                <div className="form-group"> <label>Budget</label> <div className="form-radio-group"> <label> <input type="radio" name="budgetType" value="Fixed Rate" checked={formData.budgetType === 'Fixed Rate'} onChange={handleChange} /> Fixed Rate <input type="number" name="budgetAmount" className="form-input budget-input" value={formData.budgetType === 'Fixed Rate' ? formData.budgetAmount : ''} onChange={handleChange} disabled={formData.budgetType !== 'Fixed Rate'} placeholder="0.00"/> </label> <label> <input type="radio" name="budgetType" value="Hourly Rate" checked={formData.budgetType === 'Hourly Rate'} onChange={handleChange} /> Hourly Rate <input type="number" name="budgetAmount" className="form-input budget-input" value={formData.budgetType === 'Hourly Rate' ? formData.budgetAmount : ''} onChange={handleChange} disabled={formData.budgetType !== 'Hourly Rate'} placeholder="0.00"/> </label> </div> </div>
              </div>
              {/* Description */}
              <div className="form-group"> <label htmlFor="description" className="required">Description</label> <textarea id="description" name="description" className="form-textarea" placeholder="Describe job details..." value={formData.description} onChange={handleChange} required /> </div>
              {/* Image Upload */}
              <div className="form-group-upload"> <label htmlFor="imageFile">Upload Image (Optional)</label> <p style={{color: 'var(--muted)', margin: '-5px 0 10px'}}>Add photo related to the job.</p> <input type="file" id="imageFile" name="imageFile" className="form-file-input" accept="image/png, image/jpeg, image/webp" onChange={handleFileChange} /> </div>
              {/* Terms Checkbox */}
              <div className="form-check"> <input type="checkbox" id="agreeToTerms" name="agreeToTerms" checked={formData.agreeToTerms} onChange={handleChange} required /> <label htmlFor="agreeToTerms"> I agree to Safety & Trust policy and terms of service </label> </div>
              {/* Error Display */}
              {error && <p style={{ color: "#ff8a8a" }}>{error}</p>}
              {/* Action Buttons */}
              <div className="form-actions"> <button type="submit" className="btn btn-primary"> Next: Review </button> <button type="button" className="btn btn-outline btn-save">Save Draft</button> </div>
            </form>
          )}

          {/* Step 2: Review Panel */}
          {step === 2 && (
            <ReviewPanel
                formData={formData}
                locationAddress={locationAddress}
                imageFile={imageFile}
                onBack={() => setStep(1)}
                onSubmit={handleSubmitToFirebase}
                loading={loading}
                error={error}
            />
           )}
        </div>

        {/* Sidebar */}
        <aside className="post-job-sidebar">
          <div className="sidebar-section"> <h3>Tips</h3> <ul> <li>Use clear language.</li> <li>Be precise about skills.</li> <li>Set a fair budget.</li> </ul> </div>
        </aside>
      </div>
    </div>
  );
}

// --- Map Picker Component ---
function MapPicker({ setMarker, setLocationAddress }) {
  const { isLoaded, loadError } = useLoadScript({ googleMapsApiKey: GOOGLE_MAPS_API_KEY, libraries: mapLibraries });
  const [selected, setSelected] = useState(null);
  const onMapClick = (e) => {
    const lat = e.latLng.lat(); const lng = e.latLng.lng(); const newMarker = { lat, lng };
    setSelected(newMarker); setMarker(newMarker);
    const geocoder = new window.google.maps.Geocoder();
    geocoder.geocode({ location: newMarker }, (results, status) => {
      if (status === "OK") { if (results[0]) { setLocationAddress(results[0].formatted_address); } else { setLocationAddress("Address not found"); } }
      else { console.error("Geocoder failed due to: " + status); setLocationAddress("Geocoder failed"); } // Added console error
    });
  };
  if (loadError) { console.error("Map Load Error:", loadError); return "Error loading maps"; } // Added console error
  if (!isLoaded) return "Loading Maps...";
  return ( <GoogleMap mapContainerStyle={mapContainerStyle} zoom={11} center={mapCenter} onClick={onMapClick}> {selected && ( <MarkerF position={selected} /> )} </GoogleMap> );
}

// --- Review Panel Component ---
function ReviewPanel({ formData, locationAddress, imageFile, onBack, onSubmit, loading, error }) {
  const formatBudget = (type, amount) => `₱${Number(amount).toFixed(2) || '0.00'} ${type === 'Hourly Rate' ? '/ hr' : '(Fixed)'}`;
  return (
    <div className="review-panel">
      {/* Job Details */}
      <div className="review-section"> <h3>Job Details</h3> <dl className="review-item"> <dt>Title</dt> <dd>{formData.title}</dd> </dl> <dl className="review-item"> <dt>Category</dt> <dd>{formData.category}</dd> </dl> </div>
      {/* Location & Schedule */}
      <div className="review-section"> <h3>Location & Schedule</h3> <dl className="review-item"> <dt>Work Type</dt> <dd>{formData.workType}</dd> </dl> <dl className="review-item"> <dt>Location</dt> <dd>{formData.workType === 'Online' ? 'Online' : locationAddress}</dd> </dl> <dl className="review-item"> <dt>Schedule</dt> <dd>{formData.schedule || 'Not specified'}</dd> </dl> </div>
      {/* Budget */}
      <div className="review-section"> <h3>Budget</h3> <dl className="review-item"> <dt>Details</dt> <dd>{formatBudget(formData.budgetType, formData.budgetAmount)}</dd> </dl> </div>
      {/* Image Preview */}
      {imageFile && ( <div className="review-section"> <h3>Image</h3> <dl className="review-item" style={{display: 'block'}}> <dt>Preview</dt> <dd style={{marginTop: '0.5rem'}}> <img src={URL.createObjectURL(imageFile)} alt="Job preview" style={{width: '100%', maxWidth: '300px', borderRadius: '10px'}} /> </dd> </dl> </div> )}
      {/* Description */}
      <div className="review-section"> <h3>Description</h3> <dl className="review-item" style={{display: 'block'}}> <dt>Details</dt> <dd style={{marginTop: '0.5rem'}}>{formData.description}</dd> </dl> </div>
      {/* Error */}
      {error && <p style={{ color: "#ff8a8a" }}>{error}</p>}
      {/* Actions */}
      <div className="form-actions" style={{borderTop: 'none', paddingTop: 0, marginTop: 0}}> <button type="button" className="btn btn-secondary" onClick={onBack}> Back to Edit </button> <button type="button" className="btn btn-primary btn-save" onClick={onSubmit} disabled={loading} > {loading ? "Submitting..." : "Submit Job"} </button> </div>
    </div>
  );
}