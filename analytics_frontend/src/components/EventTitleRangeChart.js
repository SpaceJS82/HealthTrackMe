import React, { useEffect, useState } from 'react';
import TimeSeriesChart from './TimeSeriesChart';

export default function EventTitleRangeChart() {
  const [titles, setTitles] = useState([]);
  const [selectedTitle, setSelectedTitle] = useState('');
  const [startDate, setStartDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() - 7);
    return d.toISOString().split('T')[0];
  });
  const [endDate, setEndDate] = useState(() => new Date().toISOString().split('T')[0]);
  const [chartData, setChartData] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('token');

    fetch('https://api.getyoa.app/yoaapi/analytics/events/titles', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(json => {
        if (json.error) throw new Error(json.error);
        setTitles(json.data);
        if (json.data.length > 0) setSelectedTitle(json.data[0]);
      })
      .catch(err => {
        console.error(err);
        setError('Failed to load event titles');
      });
  }, []);

  useEffect(() => {
    if (!selectedTitle || !startDate || !endDate) return;

    const token = sessionStorage.getItem('token');
    setLoading(true);
    setError(null);

    fetch(`https://api.getyoa.app/yoaapi/analytics/events/count-by-title?title=${encodeURIComponent(selectedTitle)}&startDate=${startDate}&endDate=${endDate}`, {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(json => {
        if (json.error) throw new Error(json.error);
        setChartData(json.data);
        setLoading(false);
      })
      .catch(err => {
        console.error(err);
        setError('Failed to load event counts');
        setLoading(false);
      });
  }, [selectedTitle, startDate, endDate]);

  return (
    <div style={{ maxWidth: 700, margin: 'auto', padding: 20 }}>
      <h2>Event Counts by Title and Date Range</h2>

      <div style={{ marginBottom: 12 }}>
        <label>
          Start Date:{' '}
          <input
            type="date"
            value={startDate}
            max={endDate}
            onChange={e => setStartDate(e.target.value)}
          />
        </label>
      </div>

      <div style={{ marginBottom: 12 }}>
        <label>
          End Date:{' '}
          <input
            type="date"
            value={endDate}
            min={startDate}
            max={new Date().toISOString().split('T')[0]}
            onChange={e => setEndDate(e.target.value)}
          />
        </label>
      </div>

      <div style={{ marginBottom: 24 }}>
        <label>
          Event Title:{' '}
          <select
            value={selectedTitle}
            onChange={e => setSelectedTitle(e.target.value)}
          >
            {titles.map(t => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </label>
      </div>

      {loading && <p>Loading chart data...</p>}
      {error && <p style={{ color: 'red' }}>{error}</p>}

      {!loading && !error && chartData.length > 0 && (
        <TimeSeriesChart
          data={chartData.map(({ date, count }) => ({ date, count }))}
          granularity="daily"
          title={`Daily counts for "${selectedTitle}"`}
        />
      )}

      {!loading && !error && chartData.length === 0 && (
        <p>No events found for the selected title and date range.</p>
      )}
    </div>
  );
}