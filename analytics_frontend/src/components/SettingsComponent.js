import React, { useEffect, useState } from 'react';
import TimeSeriesChart from './TimeSeriesChart';
import MultiLineEventChart from './MultiEventChart';


export default function Dashboard() {
  const [dailyData, setDailyData] = useState([]);
  const [weeklyData, setWeeklyData] = useState([]);
  const [monthlyData, setMonthlyData] = useState([]);
  const [avg_friends, setAvgFriends] = useState(null);
  const [selected, setSelected] = useState('daily');
  const [eventGranularity, setEventGranularity] = useState('daily');
  const [eventPerDay, setEventPerDay] = useState([]);
  const [eventPerWeek, setEventPerWeek] = useState([]);
  const [eventPerMonth, setEventPerMonth] = useState([]);

  function groupEventsByDateAndType(data) {
    const grouped = {};
    data.forEach(({ date, type, count }) => {
      if (!grouped[date]) grouped[date] = { date };
      grouped[date][type] = count;
    });
    return Object.values(grouped);
  }

  

  useEffect(() => {
    fetch('http://localhost:1004/analytics/users/avg-friends', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(data => setAvgFriends(data.average))
      .catch(console.error);
  }, []);

useEffect(() => {
  fetch('http://localhost:1004/analytics/users/new-users/daily', {
    headers: {
      'Authorization': `Bearer ${sessionStorage.getItem('token')}`
    }
  })
    .then(res => res.json())
    .then(setDailyData)
    .catch(console.error);
}, []);

  useEffect(() => {
    fetch('http://localhost:1004/analytics/users/new-users/weekly', {
    headers: {
      'Authorization': `Bearer ${sessionStorage.getItem('token')}`
    }
  })
      .then(res => res.json())
      .then(setWeeklyData)
      .catch(console.error);
  }, []);

  useEffect(() => {
    fetch('http://localhost:1004/analytics/users/new-users/monthly', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(setMonthlyData)
      .catch(console.error);
    }, []);

  useEffect(() => {
    fetch('http://localhost:1004/analytics/events/per-day', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(setEventPerDay)
      .catch(console.error);
    fetch('http://localhost:1004/analytics/events/per-week', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(setEventPerWeek)
      .catch(console.error);
      
    fetch('http://localhost:1004/analytics/events/per-month', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(setEventPerMonth)
      .catch(console.error);
  }, []);

    let eventChartData, eventChartGranularity, eventChartTitle;
  if (eventGranularity === 'daily') {
    eventChartData = eventPerDay;
    eventChartGranularity = 'daily';
    eventChartTitle = 'Events Per Day (by type)';
  } else if (eventGranularity === 'weekly') {
    eventChartData = eventPerWeek;
    eventChartGranularity = 'weekly';
    eventChartTitle = 'Events Per Week (by type)';
  } else {
    eventChartData = eventPerMonth;
    eventChartGranularity = 'monthly';
    eventChartTitle = 'Events Per Month (by type)';
  }

     let chartData, granularity, title;
  if (selected === 'daily') {
    chartData = dailyData;
    granularity = 'daily';
    title = 'Daily New Users';
  } else if (selected === 'weekly') {
    chartData = weeklyData;
    granularity = 'weekly';
    title = 'Weekly New Users';
  } else {
    chartData = monthlyData;
    granularity = 'monthly';
    title = 'Monthly New Users';
  }

  // Before your return statement in Dashboard:
console.log('Grouped event data:', groupEventsByDateAndType(eventChartData));
console.log('Event types:', Array.from(new Set(eventChartData.map(d => d.type))));

  return (
    <div>
      <div style={{ marginBottom: 16 }}>
        <label>
          Show:
          <select value={selected} onChange={e => setSelected(e.target.value)} style={{ marginLeft: 8 }}>
            <option value="daily">Daily New Users</option>
            <option value="weekly">Weekly New Users</option>
            <option value="monthly">Monthly New Users</option>
          </select>
        </label>
      </div>
      <TimeSeriesChart 
        data={chartData}
        granularity={granularity}
        title={title}
      />

      <div
        style={{
          border: '1px solid #ccc',
          borderRadius: '8px',
          padding: '16px',
          marginTop: '24px',
          width: '220px',
          marginLeft: 'auto',
          marginRight: 'auto',
          textAlign: 'center',
          background: '#fafafa'
        }}
      >
        <h3 style={{ margin: 0, fontWeight: 400 }}>Avg friends per user:</h3>
        <h2 style={{ margin: '12px 0 0 0', fontWeight: 600 }}>
          {avg_friends?.toFixed(2)}
        </h2>
      </div>

      <div style={{ marginBottom: 16, marginTop: 32 }}>
      <label>
        Show events:
        <select value={eventGranularity} onChange={e => setEventGranularity(e.target.value)} style={{ marginLeft: 8 }}>
          <option value="daily">Daily Events</option>
          <option value="weekly">Weekly Events</option>
          <option value="monthly">Monthly Events</option>
        </select>
      </label>
    </div>
    {groupEventsByDateAndType(eventChartData).length > 0 &&
      Array.from(new Set(eventChartData.map(d => d.type))).length > 0 && (
        <MultiLineEventChart
          data={groupEventsByDateAndType(eventChartData)}
          eventTypes={Array.from(new Set(eventChartData.map(d => d.type)))}
          granularity={eventChartGranularity}
          title={eventChartTitle}
        />
      )}
    </div>
  );
}
