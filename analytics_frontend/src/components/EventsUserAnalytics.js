import React, { useEffect, useState } from 'react';

export default function EventsUserAnalytics() {
  const [topUsers, setTopUsers] = useState([]);
  const [avgTimeBetween, setAvgTimeBetween] = useState([]);
  const [typeDistribution, setTypeDistribution] = useState([]);
  const [searchAvg, setSearchAvg] = useState('');
  const [searchDist, setSearchDist] = useState('');

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    fetch('http://localhost:1004/analytics/events/top-users', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTopUsers(Array.isArray(data) ? data : []))
      .catch(() => setTopUsers([]));

    fetch('http://localhost:1004/analytics/events/avg-time-between', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setAvgTimeBetween(Array.isArray(data) ? data : []))
      .catch(() => setAvgTimeBetween([]));

    fetch('http://localhost:1004/analytics/events/type-distribution', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTypeDistribution(Array.isArray(data) ? data : []))
      .catch(() => setTypeDistribution([]));
  }, []);

  // Find all event type columns that exist for at least one user and are not empty
  const allTypeKeys = Array.from(
    new Set(
      typeDistribution.flatMap(u =>
        Object.keys(u).filter(
          k => k.endsWith('_pct') && u[k] !== undefined && u[k] !== null
        )
      )
    )
  );

  // Only show users with avg_hours !== null and matching search
  const filteredAvg = avgTimeBetween.filter(
    u =>
      u.avg_hours !== null &&
      u.username &&
      u.username.toLowerCase().includes(searchAvg.toLowerCase())
  );

  // Only show users with at least one event type percentage and matching search
  const filteredDist = typeDistribution.filter(u =>
    u.username &&
    u.username.toLowerCase().includes(searchDist.toLowerCase()) &&
    allTypeKeys.some(type => u[type] !== undefined && u[type] !== null)
  );

  return (
    <div style={{ margin: "32px 0" }}>
      <h2><b>Event User Analytics</b></h2>

      <h3>Top 10 Users by Number of Events</h3>
      <table style={{ width: "100%", borderCollapse: "collapse", marginBottom: 24 }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>User</th>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Name</th>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Events</th>
          </tr>
        </thead>
        <tbody>
          {topUsers.map(u => (
            <tr key={u.user_iduser}>
              <td>{u.user?.username || u.user_iduser}</td>
              <td>{u.user?.name || ''}</td>
              <td>{u.event_count}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h3>Average Time Between Events (hours)</h3>
      <input
        type="text"
        placeholder="Search by username..."
        value={searchAvg}
        onChange={e => setSearchAvg(e.target.value)}
        style={{ marginBottom: 8, padding: 4, width: 220 }}
      />
      <table style={{ width: "100%", borderCollapse: "collapse", marginBottom: 24 }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>User</th>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Avg Time (h)</th>
          </tr>
        </thead>
        <tbody>
          {filteredAvg.map(u => (
            <tr key={u.user_id}>
              <td>{u.username}</td>
              <td>{u.avg_hours !== null ? u.avg_hours.toFixed(2) : 'N/A'}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h3>Event Type Distribution per User (%)</h3>
      <input
        type="text"
        placeholder="Search by username..."
        value={searchDist}
        onChange={e => setSearchDist(e.target.value)}
        style={{ marginBottom: 8, padding: 4, width: 220 }}
      />
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>User</th>
            {allTypeKeys.map(type => (
              <th key={type} style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>
                {type.replace('_pct', '')}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {filteredDist.map(u => (
            <tr key={u.user_id}>
              <td>{u.username}</td>
              {allTypeKeys.map(type => (
                <td key={type}>
                  {u[type] !== undefined && u[type] !== null ? u[type] + '%' : '-'}
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}