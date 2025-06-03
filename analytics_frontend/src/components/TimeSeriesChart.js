import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, Legend
} from 'recharts';

// Custom function to parse weekly dates
function parseWeeklyDate(weekStr) {
  const [year, week] = weekStr.split('-W').map(Number);
  // Create a date object for the first day of the year
  const date = new Date(year, 0, 1);
  // Add the number of weeks to get the correct date
  date.setDate(date.getDate() + (week - 1) * 7);
  return date;
}

function formatDate(dateStr, granularity) {
  if (granularity === 'monthly') {
    const [year, month] = dateStr.split('-');
    return `${year}-${month}`;
  }

  if (granularity === 'weekly') {
    return dateStr;
  }

  const date = new Date(dateStr);
  switch (granularity) {
    case 'daily':
      return date.toLocaleDateString();
    default:
      return date.toISOString();
  }
}

export default function TimeSeriesChart({
  data,
  granularity = 'daily',
  title = 'New Users Over Time',
  lines = [{ dataKey: 'count', color: '#8884d8', name: 'Count' }]
}) {
  const sortedData = [...data].sort((a, b) => {
    if (granularity === 'weekly') {
      return parseWeeklyDate(a.date) - parseWeeklyDate(b.date);
    } else {
      return new Date(a.date) - new Date(b.date);
    }
  });

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
          <Legend />
          {lines.map(line => (
            <Line
              key={line.dataKey}
              type="monotone"
              dataKey={line.dataKey}
              stroke={line.color}
              name={line.name}
              dot={false}
            />
          ))}
        </LineChart>
      </ResponsiveContainer>
    </div>
  );
}