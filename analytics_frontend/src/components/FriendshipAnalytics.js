import React, { useEffect, useState } from 'react';
import TimeSeriesChart from './TimeSeriesChart';
import { BarChart } from '@mui/x-charts/BarChart';

export default function FriendshipAnalytics() {
  const [chartData, setChartData] = useState([]);
  const [inviteConversion, setInviteConversion] = useState(null);
  const [avgFriends, setAvgFriends] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    Promise.all([
      fetch('https://api.getyoa.app/yoaapi/analytics/friendship/per-day', {
        headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` },
      }).then((res) => res.json()),
      fetch('https://api.getyoa.app/yoaapi/analytics/friendship/invites-per-day', {
        headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` },
      }).then((res) => res.json()),
      fetch('https://api.getyoa.app/yoaapi/analytics/friendship/invite-conversion', {
        headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` },
      }).then((res) => res.json()),
    ])
      .then(([friendships, invites, conversion]) => {
        const safeFriendships = Array.isArray(friendships) ? friendships : [];
        const safeInvites = Array.isArray(invites) ? invites : [];

        const allDates = Array.from(
          new Set([
            ...safeFriendships.map((f) => f.date),
            ...safeInvites.map((i) => i.date),
          ])
        ).sort();

        const merged = allDates.map((date) => ({
          date,
          friendships: safeFriendships.find((f) => f.date === date)?.count || 0,
          invites: safeInvites.find((i) => i.date === date)?.count || 0,
        }));

        setChartData(merged);
        setInviteConversion(
          conversion && typeof conversion === 'object' && !conversion.error
            ? conversion
            : null
        );
      })
      .catch(() => {
        setChartData([]);
        setInviteConversion(null);
      });
  }, []);

  useEffect(() => {
    fetch('https://api.getyoa.app/yoaapi/analytics/users/avg-friends', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` },zation: `Bearer ${sessionStorage.getItem('token')}`,
      
    })
      .then((res) => res.json())
      .then((data) => setAvgFriends(data.average))
      .catch(console.error);
  }, []);

  const conversionRate =
    inviteConversion && inviteConversion.invites_sent > 0
      ? (
          (inviteConversion.friendships_created / inviteConversion.invites_sent) *
          100
        ).toFixed(2)
      : null;

  return (
    <div style={{ margin: '32px 0' }}>
      <h2>
        <b>Friendship Analytics</b>
      </h2>
      {chartData.length === 0 ? (
        <div>No data</div>
      ) : (
        <TimeSeriesChart
          data={chartData}
          granularity="daily"
          title="Friendships Created vs Invites Sent Per Day"
          lines={[
            {
              dataKey: 'friendships',
              color: '#007bff',
              name: 'Friendships Created',
            },
            { dataKey: 'invites', color: '#ff9800', name: 'Invites Sent' },
          ]}
        />
      )}

      <h3 style={{ marginTop: 32 }}>Invite Conversion Rate</h3>
      {inviteConversion ? (
        <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
          <div style={{ ...styles.barCard }}>
            <BarChart
              xAxis={[
                {
                  data: ['Invites Sent', 'Friendships Created'],
                  scaleType: 'band',
                },
              ]}
              series={[
                {
                  data: [
                    inviteConversion.invites_sent || 0,
                    inviteConversion.friendships_created || 0,
                  ],
                  color: '#1976d2',
                },
              ]}
              height={200}
              slotProps={{
                bar: {
                  barWidth: 30,
                },
              }}
            />
          </div>
          <div style={{ ...styles.card }}>
            <h3 style={{ margin: 0, fontWeight: 400 }}>
              Accepted friendships:
            </h3>
            <h2 style={{ margin: '12px 0 0 0', fontWeight: 600 }}>
              {conversionRate !== null ? `${conversionRate}%` : 'N/A'}
            </h2>
          </div>
          <div style={{ ...styles.card }}>
            <h3 style={{ margin: 0, fontWeight: 400 }}>Avg friends per user:</h3>
            <h2 style={{ margin: '12px 0 0 0', fontWeight: 600 }}>
              {avgFriends?.toFixed(2)}
            </h2>
          </div>
        </div>
      ) : (
        <div>No data</div>
      )}
    </div>
  );
}

const styles = {
  barCard: {
    border: '1px solid #ccc',
    borderRadius: 8,
    padding: 16,
    background: '#fafafa',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
    height: '200px',
    flex: 2, // Wider flex for the bar chart
    display: 'flex',
    justifyContent: 'center',
    alignItems: 'center',
  },
  card: {
    border: '1px solid #ccc',
    borderRadius: 8,
    padding: 16,
    background: '#fafafa',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)',
    height: '200px',
    flex: 1, // Narrower flex for the other cards
    display: 'flex',
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
  },
};
