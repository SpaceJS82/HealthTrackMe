import { useEffect, useState } from 'react';

export default function ReactionsAnalytics() {
  const [topEvents, setTopEvents] = useState([]);
  const [reactionTypes, setReactionTypes] = useState([]);
  const [mostCommonReaction, setMostCommonReaction] = useState(null);

  useEffect(() => {
    const token = sessionStorage.getItem('token');
    fetch('https://api.getyoa.app/yoaapi/analytics/reactions/top-events', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setTopEvents(Array.isArray(data) ? data : []))
      .catch(() => setTopEvents([]));

    fetch('https://api.getyoa.app/yoaapi/analytics/reactions/reaction-types', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setReactionTypes(Array.isArray(data) ? data : []))
      .catch(() => setReactionTypes([]));

    fetch('https://api.getyoa.app/yoaapi/analytics/reactions/most-common', {
      headers: { 'Content-Type': 'application/json','Authorization': `Bearer ${token}` }
    })
      .then(res => res.json())
      .then(data => setMostCommonReaction(data && !data.error ? data : null))
      .catch(() => setMostCommonReaction(null));
  }, []);

  return (
    <div style={{ margin: "32px 0" }}>
      <h2>Reactions Analytics</h2>

      <h3>Top 10 Events by Reactions</h3>
      {topEvents.length === 0 ? (
        <div>No data</div>
      ) : (
        <table style={{ width: "100%", borderCollapse: "collapse" }}>
          <thead>
            <tr>
              <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Event Type</th>
              <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Creator</th>
              <th style={{ textAlign: "left", borderBottom: "1px solid #ccc" }}>Reactions</th>
            </tr>
          </thead>
          <tbody>
            {topEvents.map(ev => (
              <tr key={ev.event_idevent}>
                <td>{ev.event_name}</td>
                <td>{ev.creator_name}</td>
                <td>{ev.reaction_count}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <h3 style={{ marginTop: 24 }}>Reaction Types</h3>
      {reactionTypes.length === 0 ? (
        <div>No data</div>
      ) : (
        <ul>
          {reactionTypes.map(rt => (
            <li key={rt.reaction}>
              <strong>{rt.reaction}:</strong> {rt.count}
            </li>
          ))}
        </ul>
      )}

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