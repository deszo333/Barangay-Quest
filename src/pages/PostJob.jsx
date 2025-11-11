import React, { useState, useEffect } from 'react';
import { useOutletContext, useNavigate } from 'react-router-dom';
import { db } from '../firebase';
import {
    collection, addDoc, serverTimestamp, doc, updateDoc, increment,
    runTransaction, getDoc
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

// --- Predefined Categories (for consistency) ---
const CATEGORIES = [
  "Tutoring", "Home Repair", "Gardening", "Photography", "Errands",
  "Child Care", "Elder Care", "Cleaning", "Pet Care", "Transport",
  "Test Prep", "Bookkeeping", "Catering", "PC Help", "Design",
  "Events", "Other"
];

// --- Helper function to get today's date in YYYY-MM-DD format ---
const getTodayString = () => {
  const today = new Date();
  const year = today.getFullYear();
  const month = (today.getMonth() + 1).toString().padStart(2, '0');
  const day = today.getDate().toString().padStart(2, '0');
  return `${year}-${month}-${day}`;
};

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
  
  const [specificDate, setSpecificDate] = useState("");
  const [today, setToday] = useState(getTodayString());

  const [formData, setFormData] = useState({
    title: '',
    category: CATEGORIES[0], 
    workType: 'In Person',
    price: '',
    description: '',
    agreeToTerms: false,
  });

  const handleChange = (e) => {
    const { name, value, type, checked } = e.target;
    setFormData(prevData => ({ ...prevData, [name]: type === 'checkbox' ? checked : value }));
  };

  const handleFileChange = (e) => { if (e.target.files[0]) { setImageFile(e.target.files[0]); } };

  const handleGoToReview = (e) => {
    e.preventDefault();
    setError(null);
    
    if (!user) {
      setError("You must be logged in to post a job."); return;
    }
    if (!formData.agreeToTerms) { 
      setError("You must agree to the terms of service."); return; 
    }
    if (formData.workType === 'In Person' && !marker) { 
      setError("Please pin the job location on the map."); return; 
    }

    // Price Validation
    const priceAmount = Number(formData.price);
    if (!priceAmount || priceAmount <= 0) {
      setError("Please enter a valid price (must be greater than 0).");
      return;
    }
    if ((user.walletBalance || 0) < priceAmount) {
      setError("Your wallet balance is too low to post this job. Please add credits to your Profile page.");
      return;
    }
    
    // Date Validation
    if (!specificDate) {
      setError("Please specify the date for the job.");
      return;
    }
    const selectedDateTime = new Date(specificDate).getTime();
    const todayDateTime = new Date(getTodayString()).getTime();
    if (selectedDateTime < todayDateTime) {
       setError("You cannot select a date in the past.");
       return;
    }
    const twoYearsFromNow = new Date();
    twoYearsFromNow.setFullYear(twoYearsFromNow.getFullYear() + 2);
    if (selectedDateTime > twoYearsFromNow.getTime()) {
       setError("Date cannot be more than 2 years in the future.");
       return;
    }
    
    setStep(2);
  };

  // Submit Function
  const handleSubmitToFirebase = async () => {
    if (!user) { setError("User not found. Please log in again."); return; }

    setLoading(true); setError(null);
    let imageUrl = null;

    try {
      if (imageFile) {
        const storage = getStorage();
        const imagePath = `quest_images/${user.uid}/${Date.now()}_${imageFile.name}`;
        const storageRef = ref(storage, imagePath);
        const snapshot = await uploadBytes(storageRef, imageFile);
        imageUrl = await getDownloadURL(snapshot.ref);
      }

      await runTransaction(db, async (transaction) => {
        const userRef = doc(db, "users", user.uid);
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists()) { throw new Error("User profile not found!"); }
        
        // Just increment the post count
        const userUpdates = { questsPosted: increment(1) };
        transaction.update(userRef, userUpdates);

        // Create the new quest
        const newQuestRef = doc(collection(db, "quests"));
    transaction.set(newQuestRef, {
      title: formData.title,
      category: formData.category,
      workType: formData.workType,
      description: formData.description,
      agreeToTerms: formData.agreeToTerms,
      price: Number(formData.price),
      engagement: "One-Time",
      priceType: "Fixed Rate",
      schedule: "Specific Date",
      specificDate: specificDate, // Save the chosen date
      location: {
        lat: marker ? marker.lat : null,
        lng: marker ? marker.lng : null,
        address: locationAddress || (formData.workType === 'Online' ? 'Online' : 'Location Not Pinned')
       },
      imageUrl: imageUrl,
      questGiverId: user.uid,
      questGiverName: user.name,
      status: 'open',
      createdAt: serverTimestamp()
    });
      }); // End Transaction

      setLoading(false);
      navigate("/my-quests");

    } catch (err) {
      console.error("Error posting job:", err);
      setError(`Error during submission: ${err.message}`);
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
              <div className="form-group">
                <label htmlFor="title" className="required">Job Title</label>
                <input type="text" id="title" name="title" className="form-input" value={formData.title} onChange={handleChange} required />
              </div>
              
              {/* Category (Dropdown) */}
              <div className="form-group">
                <label htmlFor="category" className="required">Category</label>
                <select id="category" name="category" className="form-select" value={formData.category} onChange={handleChange} required>
                  {CATEGORIES.map(cat => (
                    <option key={cat} value={cat}>{cat}</option>
                  ))}
                </select>
              </div>

              {/* --- REMOVED: Engagement Toggle --- */}

              {/* Work Type */}
              <div className="form-group">
                <label>Work Type</label>
                <div className="form-toggle">
                  <input type="radio" id="workTypeInPerson" name="workType" value="In Person" checked={formData.workType === 'In Person'} onChange={handleChange}/>
                  <label htmlFor="workTypeInPerson">In Person</label>
                  <input type="radio" id="workTypeOnline" name="workType" value="Online" checked={formData.workType === 'Online'} onChange={handleChange}/>
                  <label htmlFor="workTypeOnline">Online</label>
                </div>
              </div>

              {/* Location Map (Conditional) */}
              {formData.workType === 'In Person' && (
                <div className="form-group">
                  <label htmlFor="location" className="required">Pin Job Location</label>
                  <p style={{color: 'var(--muted)', margin: '-5px 0 10px'}}>Click map to drop pin.</p>
                  <MapPicker setMarker={setMarker} setLocationAddress={setLocationAddress}/>
                  {locationAddress && (
                    <input type="text" className="form-input" value={locationAddress} readOnly style={{marginTop: '10px', background: 'var(--bg)'}} />
                  )}
                </div>
              )}
              
              {/* --- UPDATED: Schedule & Budget are now stacked --- */}
              
              {/* --- UPDATED: Schedule is now just a date picker --- */}
              <div className="form-group">
                <label htmlFor="specificDate" className="required">Date of Job</label>
                <input
                  type="date"
                  id="specificDate"
                  name="specificDate"
                  className="form-input"
                  value={specificDate}
                  onChange={(e) => setSpecificDate(e.target.value)}
                  min={today}
                  required
                />
              </div>

              {/* --- UPDATED: Budget is now a single field --- */}
              <div className="form-group">
                <label className="required" htmlFor="price">Price (Fixed Rate)</label>
                <input
                  type="number"
                  name="price"
                  id="price"
                  className="form-input"
                  value={formData.price}
                  onChange={handleChange}
                  placeholder="₱0.00"
                  required
                  min="1"
                />
              </div>
              
              {/* Description */}
              <div className="form-group">
                <label htmlFor="description" className="required">Description</label>
                <textarea id="description" name="description" className="form-textarea" placeholder="Describe job details..." value={formData.description} onChange={handleChange} required />
              </div>
              
              {/* Image Upload */}
              <div className="form-group-upload">
                <label htmlFor="imageFile">Upload Image (Optional)</label>
                <p style={{color: 'var(--muted)', margin: '-5px 0 10px'}}>Add photo related to the job.</p>
                <input type="file" id="imageFile" name="imageFile" className="form-file-input" accept="image/png, image/jpeg, image/webp" onChange={handleFileChange} />
              </div>

              {/* Terms Checkbox */}
              <div className="form-check">
                <input type="checkbox" id="agreeToTerms" name="agreeToTerms" checked={formData.agreeToTerms} onChange={handleChange} required />
                <label htmlFor="agreeToTerms"> I agree to Safety & Trust policy and terms of service </label>
              </div>
              
              {/* Error Display */}
              {error && <p style={{ color: "#ff8a8a" }}>{error}</p>}
              
              {/* Action Buttons */}
              <div className="form-actions">
                <button type="submit" className="btn btn-primary"> Next: Review </button>
              </div>
            </form>
          )}

          {/* Step 2: Review Panel */}
          {step === 2 && (
            <ReviewPanel
                formData={formData}
                locationAddress={locationAddress}
                imageFile={imageFile}
                specificDate={specificDate} 
                onBack={() => setStep(1)}
                onSubmit={handleSubmitToFirebase}
                loading={loading}
                error={error}
            />
           )}
        </div>

        {/* Sidebar */}
        <aside className="post-job-sidebar">
          <div className="sidebar-section">
            <h3>Tips</h3>
            <ul>
              <li>Use clear language.</li>
              <li>Be precise about skills.</li>
              <li>Set a fair budget.</li>
            </ul>
          </div>
        </aside>
      </div>
    </div>
  );
}

// --- Map Picker Component (Unchanged) ---
function MapPicker({ setMarker, setLocationAddress }) {
  const { isLoaded, loadError } = useLoadScript({ googleMapsApiKey: GOOGLE_MAPS_API_KEY, libraries: mapLibraries });
  const [selected, setSelected] = useState(null);
  const onMapClick = (e) => {
    const lat = e.latLng.lat(); const lng = e.latLng.lng(); const newMarker = { lat, lng };
    setSelected(newMarker); setMarker(newMarker);
    const geocoder = new window.google.maps.Geocoder();
    geocoder.geocode({ location: newMarker }, (results, status) => {
      if (status === "OK") { if (results[0]) { setLocationAddress(results[0].formatted_address); } else { setLocationAddress("Address not found"); } }
      else { console.error("Geocoder failed due to: " + status); setLocationAddress("Geocoder failed"); }
    });
  };
  if (loadError) { console.error("Map Load Error:", loadError); return "Error loading maps"; }
  if (!isLoaded) return "Loading Maps...";
  return ( <GoogleMap mapContainerStyle={mapContainerStyle} zoom={11} center={mapCenter} onClick={onMapClick}> {selected && ( <MarkerF position={selected} /> )} </GoogleMap> );
}

// --- Review Panel Component (Simplified) ---
function ReviewPanel({ formData, locationAddress, imageFile, specificDate, onBack, onSubmit, loading, error }) {
  const formatBudget = (type, amount) => `₱${Number(amount).toFixed(2) || '0.00'} (Fixed)`;
  
  const formattedDate = () => {
    if (specificDate) {
      try {
        return new Date(specificDate).toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric'
        });
      } catch (e) {
        return specificDate; // fallback
      }
    }
    return 'N/A';
  };
  
  return (
    <div className="review-panel">
      {/* Job Details */}
      <div className="review-section">
        <h3>Job Details</h3>
        <dl className="review-item"> <dt>Title</dt> <dd>{formData.title}</dd> </dl>
        <dl className="review-item"> <dt>Category</dt> <dd>{formData.category}</dd> </dl>
        <dl className="review-item"> <dt>Engagement</dt> <dd>One-Time Project</dd> </dl>
      </div>
      {/* Location & Schedule */}
      <div className="review-section">
        <h3>Location & Schedule</h3>
        <dl className="review-item"> <dt>Work Type</dt> <dd>{formData.workType}</dd> </dl>
        <dl className="review-item"> <dt>Location</dt> <dd>{formData.workType === 'Online' ? 'Online' : locationAddress}</dd> </dl>
        <dl className="review-item"> <dt>Date</dt> <dd>{formattedDate()}</dd> </dl>
      </div>
      {/* Budget */}
  <div className="review-section"> <h3>Budget</h3> <dl className="review-item"> <dt>Details</dt> <dd>{formatBudget(null, formData.price)}</dd> </dl> </div>
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