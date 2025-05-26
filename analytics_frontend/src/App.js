import React, { useState } from "react";
import "./App.css";

const HomeComponent = () => <div className="content">🏠 This is the Home component.</div>;
const SettingsComponent = () => <div className="content">⚙️ This is the Settings component.</div>;

function App() {
  const [activeTab, setActiveTab] = useState("home");

  const renderContent = () => {
    if (activeTab === "home") return <HomeComponent />;
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
