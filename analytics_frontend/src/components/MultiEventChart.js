// MultiLineEventChart.js
import React from 'react';
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';

const colors = ['#8884d8', '#82ca9d', '#ff7300', '#ff0000', '#00bcd4', '#0088FE', '#00C49F'];

export default function MultiLineEventChart({ data, eventTypes, granularity, title }) {
  return (
    <div className="p-4">
      <h2 className="text-xl font-semibold mb-2">{title}</h2>
      <ResponsiveContainer width="100%" height={300}>
        <LineChart data={data}>
          <CartesianGrid stroke="#ccc" />
          <XAxis dataKey="date" />
          <YAxis />
          <Tooltip />
          <Legend />
          {eventTypes.map((type, idx) => (
            <Line
              key={type}
              type="monotone"
              dataKey={type}
              stroke={colors[idx % colors.length]}
              dot={false}
              isAnimationActive={false}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}