import React, { useEffect, useState } from 'react';
import PaginatedTable from './PaginatedTable';
import Typography from '@mui/material/Typography';

export default function EventsUserAnalytics() {
  const [topUsers, setTopUsers] = useState([]);
  const [avgTimeBetween, setAvgTimeBetween] = useState([]);
  const [typeDistribution, setTypeDistribution] = useState([]);
  const [searchAvg, setSearchAvg] = useState('');
  const [searchDist, setSearchDist] = useState('');

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    fetch('https://api.getyoa.app/yoaapi/analytics/events/top-users', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTopUsers(Array.isArray(data) ? data : []))
      .catch(() => setTopUsers([]));

    fetch('https://api.getyoa.app/yoaapi/analytics/events/avg-time-between', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setAvgTimeBetween(Array.isArray(data) ? data : []))
      .catch(() => setAvgTimeBetween([]));

    fetch('https://api.getyoa.app/yoaapi/analytics/events/type-distribution', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTypeDistribution(Array.isArray(data) ? data : []))
      .catch(() => setTypeDistribution([]));
  }, []);

  // Find all event type columns that exist for at least one user and are not empty
  const allTypeKeys = Array.from(
    new Set(
      (Array.isArray(typeDistribution) ? typeDistribution : []).flatMap(u =>
        Object.keys(u).filter(
          k => k.endsWith('_pct') && u[k] !== undefined && u[k] !== null
        )
      )
    )
  );

  // Only show users with avg_hours !== null and matching search
  const filteredAvg = (Array.isArray(avgTimeBetween) ? avgTimeBetween : []).filter(
    u =>
      u.avg_hours !== null &&
      u.username &&
      u.username.toLowerCase().includes(searchAvg.toLowerCase())
  );

  // Only show users with at least one event type percentage and matching search
  const filteredDist = (Array.isArray(typeDistribution) ? typeDistribution : []).filter(u =>
    u.username &&
    u.username.toLowerCase().includes(searchDist.toLowerCase()) &&
    allTypeKeys.some(type => u[type] !== undefined && u[type] !== null)
  );

  // Table columns
  const topUsersColumns = [
    { id: 'username', label: 'User' },
    { id: 'name', label: 'Name' },
    { id: 'event_count', label: 'Events', align: 'right' }
  ];
  const topUsersRows = topUsers.map(u => ({
    id: u.user_iduser,
    username: u.user?.username || u.user_iduser,
    name: u.user?.name || '',
    event_count: u.event_count
  }));

  const avgTimeColumns = [
    { id: 'username', label: 'User' },
    { id: 'avg_hours', label: 'Avg Time (h)', align: 'right' }
  ];
  const avgTimeRows = filteredAvg.map(u => ({
    id: u.user_id,
    username: u.username,
    avg_hours: u.avg_hours !== null ? u.avg_hours.toFixed(2) : 'N/A'
  }));

  const distColumns = [
    { id: 'username', label: 'User' },
    ...allTypeKeys.map(type => ({
      id: type,
      label: type.replace('_pct', ''),
      align: 'right'
    }))
  ];
  const distRows = filteredDist.map(u => ({
    id: u.user_id,
    username: u.username,
    ...Object.fromEntries(
      allTypeKeys.map(type => [
        type,
        u[type] !== undefined && u[type] !== null ? `${u[type]}%` : '-'
      ])
    )
  }));

  return (
    <div style={{ margin: "32px 0" }}>
      <h2>
        <b>Event User Analytics</b>
      </h2>

      <Typography variant="h6" sx={{ mt: 2 }}>Top 10 Users by Number of Events</Typography>
      {topUsers.length === 0 ? (
        <Typography color="text.secondary">No data</Typography>
      ) : (
        <PaginatedTable columns={topUsersColumns} rows={topUsersRows} rowsPerPageOptions={[5, 10, 25]} defaultRowsPerPage={5} />
      )}

      <Typography variant="h6" sx={{ mt: 2 }}>Average Time Between Events (hours)</Typography>
      <input
        type="text"
        placeholder="Search by username..."
        value={searchAvg}
        onChange={e => setSearchAvg(e.target.value)}
        style={{ marginBottom: 8, padding: 4, width: 220 }}
      />
      {avgTimeRows.length === 0 ? (
        <Typography color="text.secondary">No data</Typography>
      ) : (
        <PaginatedTable columns={avgTimeColumns} rows={avgTimeRows} rowsPerPageOptions={[5, 10, 25]} defaultRowsPerPage={5} />
      )}

      <Typography variant="h6" sx={{ mt: 2 }}>Event Type Distribution per User (%)</Typography>
      <input
        type="text"
        placeholder="Search by username..."
        value={searchDist}
        onChange={e => setSearchDist(e.target.value)}
        style={{ marginBottom: 8, padding: 4, width: 220 }}
      />
      {filteredDist.length === 0 ? (
        <div>No data</div>
      ) : (
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
      )}
    </div>
  );
}