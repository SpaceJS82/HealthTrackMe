import React, { useState, useEffect } from "react";
import Login from "./components/login";
import Dashboard from "./components/HomeComponent"
import "./App.css";

const SettingsComponent = () => <div className="content">⚙️ This is the Settings component.</div>;

function App() {
  // Restore token from sessionStorage, but treat "null" as null
  const [token, setToken] = useState(() => {
    const stored = sessionStorage.getItem('token');
    return stored && stored !== "null" ? stored : null;
  });
  const [activeTab, setActiveTab] = useState("home");

  useEffect(() => {
    if (token) {
      sessionStorage.setItem('token', token);
    } else {
      sessionStorage.removeItem('token');
    }
  }, [token]);

  if (!token) {
    return <Login setToken={setToken} />;
  }

  const renderContent = () => {
    if (activeTab === "home") return <Dashboard />;
    if (activeTab === "settings") return <SettingsComponent />;
    return null;
  };

  return (
    <div className="container">
      <div className="sidebar">
        <h1>Yoa Analytics</h1>
        <button
          className={`tab-button ${activeTab === "home" ? "active" : ""}`}
          onClick={() => setActiveTab("home")}
        >
          🤗 Database
        </button>
        <button
          className={`tab-button ${activeTab === "settings" ? "active" : ""}`}
          onClick={() => setActiveTab("settings")}
        >
          📆 InApp Events
        </button>
      </div>
      <div className="divider"></div>
      <div className="main-content">{renderContent()}</div>
    </div>
  );
}

export default App;