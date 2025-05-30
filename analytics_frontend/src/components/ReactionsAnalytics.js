import { useEffect, useState } from 'react';

export default function ReactionsAnalytics() {
  const [topEvents, setTopEvents] = useState([]);
  const [reactionTypes, setReactionTypes] = useState([]);
  const [mostCommonReaction, setMostCommonReaction] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    fetch('http://localhost:1004/analytics/reactions/top-events', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(setTopEvents)
      .catch(console.error);

    fetch('http://localhost:1004/analytics/reactions/reaction-types', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(setReactionTypes)
      .catch(console.error);

    fetch('http://localhost:1004/analytics/reactions/most-common', {
      headers: { 'Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(setMostCommonReaction)
      .catch(console.error);
  }, []);

  return (
    <div style={{ margin: "32px 0" }}>
      <h2>Reactions Analytics</h2>

      <h3>Top 10 Events by Reactions</h3>
      <table style={{ width: "100%", borderCollapse: "collapse" }}>
        <thead>
          <tr>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Event Type</th>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Creator</th>
            <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Reactions</th>
          </tr>
        </thead>
        <tbody>
          {Array.isArray(topEvents) && topEvents.map(ev => (
            <tr key={ev.event_idevent}>
              <td>{ev.event_name}</td>
              <td>{ev.creator_name}</td>
              <td>{ev.reaction_count}</td>
            </tr>
          ))}
        </tbody>
      </table>

      <h3 style={{ marginTop: 24 }}>Reaction Types</h3>
      <ul>
        {reactionTypes.map(rt => (
          <li key={rt.reaction}>
            <strong>{rt.reaction}:</strong> {rt.count}
          </li>
        ))}
      </ul>

      <h3 style={{ marginTop: 24 }}>Most Common Reaction</h3>
      {mostCommonReaction && mostCommonReaction.reaction ? (
        <div>
          <strong>{mostCommonReaction.reaction}</strong> ({mostCommonReaction.count} times)
        </div>
      ) : (
        <div>No data</div>
      )}
    </div>
  );
}