// components/TimeSeriesChart.jsx
import React from 'react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer
} from 'recharts';

function formatDate(dateStr, granularity) {
  if (granularity === 'monthly') {
    // Show only year and month
    const [year, month] = dateStr.split('-');
    return `${year}-${month}`;
  }
  const date = new Date(dateStr);
  switch (granularity) {
    case 'daily':
      return date.toLocaleDateString();
    case 'weekly':
  return dateStr.startsWith('20') ? dateStr : `Week of ${date.toLocaleDateString()}`;
    default:
      return date.toISOString();
  }
}

export default function TimeSeriesChart({ data, granularity = 'daily', title = 'New Users Over Time' }) {
  // Ensure data is sorted (optional but often helpful)
  const sortedData = [...data].sort((a, b) => new Date(a.date) - new Date(b.date));

  return (
    <div className="p-4">
      <h2 className="text-xl font-semibold mb-2">{title}</h2>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={sortedData}>
          <CartesianGrid stroke="#ccc" />
          <XAxis 
            dataKey="date"
            tickFormatter={(date) => formatDate(date, granularity)}
          />
          <YAxis />
          <Tooltip 
            labelFormatter={(label) => formatDate(label, granularity)}
          />
          <Line type="monotone" dataKey="count" stroke="#8884d8" />
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}
