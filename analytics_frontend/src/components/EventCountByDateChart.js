import React, { useState, useEffect } from 'react';
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';

const EventCountByDateChart = () => {
  // Set default dates (7 days ago to today)
  const defaultStart = new Date();
  defaultStart.setDate(defaultStart.getDate() - 7);
  const [startDate, setStartDate] = useState(defaultStart.toISOString().split('T')[0]);
  const [endDate, setEndDate] = useState(new Date().toISOString().split('T')[0]);
  const [eventTitles, setEventTitles] = useState([]);
  const [selectedEvent, setSelectedEvent] = useState('');
  const [chartData, setChartData] = useState([]);
  const [loading, setLoading] = useState(false);

  // Fetch all unique event titles
  useEffect(() => {
    const fetchEventTitles = async () => {
      try {
        const token = sessionStorage.getItem('token');
        const response = await fetch('https://api.getyoa.app/yoaapi/analytics/inappevents/titles', { // Updated endpoint
          headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
        });
        
        // if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
        
        const data = await response.json();
        setEventTitles(data.titles || []);
        if (data.titles?.length > 0) {
          setSelectedEvent(data.titles[0]);
        }
      } catch (error) {
        console.error('Error fetching event titles:', error);
        setEventTitles([]);
      }
    };

    fetchEventTitles();
  }, []);

  // Fetch event counts when dates or selected event changes
  useEffect(() => {
    if (selectedEvent) {
      fetchEventCounts();
    }
  }, [startDate, endDate, selectedEvent]);

  const fetchEventCounts = async () => {
    setLoading(true);
    try {
      const token = sessionStorage.getItem('token');
      const params = new URLSearchParams({
        start: startDate,
        end: endDate,
        title: selectedEvent
      });

      const response = await fetch(`https://api.getyoa.app/yoaapi/analytics/inappevents/count-by-date?${params}`, {
        headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
      });

      // if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
      
      const data = await response.json();
      setChartData(data || []);
    } catch (error) {
      console.error('Error fetching event counts:', error);
      setChartData([]);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ margin: "32px 0", padding: "16px", border: "1px solid #eee", borderRadius: "8px" }}>
      <h2><b>Event Count by Date</b></h2>
      
      <div style={{ marginBottom: "24px", display: "flex", gap: "16px", flexWrap: "wrap" }}>
        <div>
          <label style={{ display: "block", marginBottom: "4px" }}>Start Date</label>
          <input
            type="date"
            value={startDate}
            onChange={e => setStartDate(e.target.value)}
            max={endDate}
            style={{ padding: "6px" }}
          />
        </div>
        
        <div>
          <label style={{ display: "block", marginBottom: "4px" }}>End Date</label>
          <input
            type="date"
            value={endDate}
            onChange={e => setEndDate(e.target.value)}
            min={startDate}
            max={new Date().toISOString().split('T')[0]}
            style={{ padding: "6px" }}
          />
        </div>
        
        <div>
          <label style={{ display: "block", marginBottom: "4px" }}>Event Type</label>
          <select 
            value={selectedEvent}
            onChange={e => setSelectedEvent(e.target.value)}
            style={{ padding: "6px", minWidth: "200px" }}
          >
            {eventTitles.map(title => (
              <option key={title} value={title}>{title}</option>
            ))}
          </select>
        </div>
      </div>

      {loading ? (
        <div>Loading data...</div>
      ) : chartData.length > 0 ? (
        <ResponsiveContainer width="100%" height={400}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" />
            <XAxis 
              dataKey="date" 
              tickFormatter={(date) => new Date(date).toLocaleDateString()} 
            />
            <YAxis />
            <Tooltip 
              labelFormatter={(date) => new Date(date).toLocaleDateString()}
            />
            <Legend />
            <Line 
              type="monotone" 
              dataKey="count" 
              name={`Count of ${selectedEvent}`}
              stroke="#8884d8" 
              activeDot={{ r: 8 }} 
            />
          </LineChart>
        </ResponsiveContainer>
      ) : (
        <div>No data available for the selected criteria</div>
      )}
    </div>
  );
};

export default EventCountByDateChart;