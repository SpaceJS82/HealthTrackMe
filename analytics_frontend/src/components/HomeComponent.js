import React, { useEffect, useState } from 'react';
import TimeSeriesChart from './TimeSeriesChart';
import MultiLineEventChart from './MultiEventChart';
import ReactionsAnalytics from './ReactionsAnalytics';
import FriendshipAnalytics from './FriendshipAnalytics';
import EventsUserAnalytics from './EventsUserAnalytics';
import './home.css';




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
  const [eventStartDate, setEventStartDate] = useState('');
  const [eventEndDate, setEventEndDate] = useState('');
  const [userStartDate, setUserStartDate] = useState('');
  const [userEndDate, setUserEndDate] = useState('');

  




function fetchEventDataByRange() {
  if (!eventStartDate || !eventEndDate) return;

  let endpoint = '';
  let setData;

  if (eventGranularity === 'daily') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/events/per-day?start=${eventStartDate}&end=${eventEndDate}`;
    setData = setEventPerDay;
  } else if (eventGranularity === 'weekly') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/events/per-week?start=${eventStartDate}&end=${eventEndDate}`;
    setData = setEventPerWeek;
  } else if (eventGranularity === 'monthly') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/events/per-month?start=${eventStartDate}&end=${eventEndDate}`;
    setData = setEventPerMonth;
  }

  fetch(endpoint, {
    headers: {
      'Authorization': `Bearer ${sessionStorage.getItem('token')}`
    }
  })
    .then(res => res.json())
    .then(setData)
    .catch(console.error);
}

  function groupEventsByDateAndType(data, granularity) {
  const grouped = {};
  data.forEach(item => {
    let xKey;
    if (granularity === 'daily') xKey = item.date;
    else if (granularity === 'weekly') xKey = item.date || String(item.week); // use .date if backend provides it, else .week
    else if (granularity === 'monthly') xKey = item.date || item.month;
    else xKey = item.date;

    if (!grouped[xKey]) grouped[xKey] = { date: xKey };
    grouped[xKey][item.type] = item.count;
  });
  return Object.values(grouped).sort((a, b) => a.date.localeCompare(b.date));
}

  

  useEffect(() => {
    fetch('https://api.getyoa.app/yoaapi/analytics/users/avg-friends', {
      headers: {
        'Authorization': `Bearer ${sessionStorage.getItem('token')}`
      }
    })
      .then(res => res.json())
      .then(data => setAvgFriends(data.average))
      .catch(console.error);
  }, []);

function fetchUserDataByRange() {
  if (!userStartDate || !userEndDate) return;

  let endpoint = '';
  let setData;

  if (selected === 'daily') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/users/new-users/daily?start=${userStartDate}&end=${userEndDate}`;
    setData = setDailyData;
  } else if (selected === 'weekly') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/users/new-users/weekly?start=${userStartDate}&end=${userEndDate}`;
    setData = setWeeklyData;
  } else if (selected === 'monthly') {
    endpoint = `https://api.getyoa.app/yoaapi/analytics/users/new-users/monthly?start=${userStartDate}&end=${userEndDate}`;
    setData = setMonthlyData;
  }

  fetch(endpoint, {
    headers: {
      'Authorization': `Bearer ${sessionStorage.getItem('token')}`
    }
  })
    .then(res => res.json())
    .then(setData)
    .catch(console.error);
}



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
  console.log('Grouped event data:', groupEventsByDateAndType(eventChartData, eventChartGranularity));
  return (
    <div style={{ padding: 32, maxWidth: 1200, margin: "0 auto" }}>
      <div style={{ display: 'flex', flexDirection: 'column', gap: '24px' }}>
        {/* New Users Filter and Chart */}
        <div style={styles.card}>
          <form style={{ display: "flex", gap: 16, alignItems: "flex-end", marginBottom: 16 }}>
            <div>
              <label>Show:<br />
                <select value={selected} onChange={e => setSelected(e.target.value)} style={{ minWidth: 160 }}>
                  <option value="daily">Daily New Users</option>
                  <option value="weekly">Weekly New Users</option>
                  <option value="monthly">Monthly New Users</option>
                </select>
              </label>
            </div>
            <div>
              <label>Start date:<br />
                <input type="date" value={userStartDate} onChange={e => setUserStartDate(e.target.value)} />
              </label>
            </div>
            <div>
              <label>End date:<br />
                <input type="date" value={userEndDate} onChange={e => setUserEndDate(e.target.value)} />
              </label>
            </div>
            <div>
              <button type="button" onClick={fetchUserDataByRange} disabled={!userStartDate || !userEndDate}>
                Apply
              </button>
            </div>
          </form>
          {chartData.length > 0 && (
            <TimeSeriesChart data={chartData} granularity={granularity} title={title} />
          )}
        </div>

        {/* Friendship Analytics */}
        <div style={styles.card}>
          <FriendshipAnalytics />
          <h3 style={{ margin: 0, fontWeight: 400 }}>Avg friends per user:</h3>
          <h2 style={{ margin: '12px 0 0 0', fontWeight: 600 }}>
            {avg_friends?.toFixed(2)}
          </h2>
        </div>

        {/* Reactions Analytics */}
        <div style={styles.card}>
          <ReactionsAnalytics />
        </div>

        {/* Events User Analytics */}
        <div style={styles.card}>
          <EventsUserAnalytics />
        </div>

        

        {/* Events Filter and Chart */}
        <div style={styles.card}>
          <form style={{ display: "flex", gap: 16, alignItems: "flex-end", marginBottom: 16 }}>
            <div>
              <label>Show events:<br />
                <select value={eventGranularity} onChange={e => setEventGranularity(e.target.value)} style={{ minWidth: 160 }}>
                  <option value="daily">Daily Events</option>
                  <option value="weekly">Weekly Events</option>
                  <option value="monthly">Monthly Events</option>
                </select>
              </label>
            </div>
            <div>
              <label>Start date:<br />
                <input type="date" value={eventStartDate} onChange={e => setEventStartDate(e.target.value)} />
              </label>
            </div>
            <div>
              <label>End date:<br />
                <input type="date" value={eventEndDate} onChange={e => setEventEndDate(e.target.value)} />
              </label>
            </div>
            <div>
              <button type="button" onClick={fetchEventDataByRange} disabled={!eventStartDate || !eventEndDate}>
                Apply
              </button>
            </div>
          </form>
          {groupEventsByDateAndType(eventChartData, eventChartGranularity).length > 0 &&
            Array.from(new Set(eventChartData.map(d => d.type))).length > 0 && (
              <MultiLineEventChart
                data={groupEventsByDateAndType(eventChartData, eventChartGranularity)}
                eventTypes={Array.from(new Set(eventChartData.map(d => d.type)))}
                granularity={eventChartGranularity}
                title={eventChartTitle}
              />
            )}
        </div>
      </div>
    </div>
  );
}

const styles = {
  card: {
    border: '1px solid #ccc',
    borderRadius: 8,
    padding: 16,
    background: '#fafafa',
    boxShadow: '0 2px 4px rgba(0, 0, 0, 0.1)'
  }
};
