import React, { useEffect, useState } from 'react';
import TimeSeriesChart from './TimeSeriesChart';

export default function FriendshipAnalytics() {
  const [chartData, setChartData] = useState([]);
  const [inviteConversion, setInviteConversion] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    Promise.all([
      fetch('http://localhost:1004/analytics/friendship/per-day', {
        headers: { 'Authorization': `Bearer ${token}` }
      }).then(res => res.json()),
      fetch('http://localhost:1004/analytics/friendship/invites-per-day', {
        headers: { 'Authorization': `Bearer ${token}` }
      }).then(res => res.json()),
      fetch('http://localhost:1004/analytics/friendship/invite-conversion', {
        headers: { 'Authorization': `Bearer ${token}` }
      }).then(res => res.json())
    ]).then(([friendships, invites, conversion]) => {
      // Merge by date for chart
      const allDates = Array.from(new Set([
        ...friendships.map(f => f.date),
        ...invites.map(i => i.date)
      ])).sort();

      const merged = allDates.map(date => ({
        date,
        friendships: friendships.find(f => f.date === date)?.count || 0,
        invites: invites.find(i => i.date === date)?.count || 0
      }));

      setChartData(merged);
      setInviteConversion(conversion);
    });
  }, []);

  return (
    <div style={{ margin: "32px 0" }}>
      <h2><b>Friendship Analytics</b></h2>
      <TimeSeriesChart
        data={chartData}
        granularity="daily"
        title="Friendships Created vs Invites Sent Per Day"
        lines={[
          { dataKey: 'friendships', color: '#007bff', name: 'Friendships Created' },
          { dataKey: 'invites', color: '#ff9800', name: 'Invites Sent' }
        ]}
      />

      <h3 style={{ marginTop: 32 }}>Invite Conversion Rate</h3>
      {inviteConversion ? (
        <div>
          <div>Invites Sent: <strong>{inviteConversion.invites_sent}</strong></div>
          <div>Friendships Created: <strong>{inviteConversion.friendships_created}</strong></div>
          <div>Conversion Rate: <strong>{inviteConversion.conversion_rate}%</strong></div>
        </div>
      ) : (
        <div>No data</div>
      )}
    </div>
  );
}