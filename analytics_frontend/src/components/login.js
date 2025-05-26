import React, { useState } from 'react';
import PropTypes from 'prop-types';

async function loginUser(credentials) {
  return fetch('http://localhost:1004/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(credentials)
  }).then(data => data.json());
}

export default function Login({ setToken }) {
  const [username, setUserName] = useState('');
  const [password, setPassword] = useState('');

  const handleSubmit = async e => {
    e.preventDefault();
    const data = await loginUser({ username, password });
    if (data.token) {
      setToken(data.token);
      sessionStorage.setItem('token', data.token);
    } else {
      alert('Login failed');
    }
  };

  return (
    <div className="login-wrapper">
      <h1>Please log in</h1>
      <form onSubmit={handleSubmit}>
        <label>
          <p>Username</p>
          <input type="text" onChange={e => setUserName(e.target.value)} />
        </label>
        <label>
          <p>Password</p>
          <input type="password" onChange={e => setPassword(e.target.value)} />
        </label>
        <div>
          <button type="submit">Submit</button>
        </div>
      </form>
    </div>
  );
}

Login.propTypes = {
  setToken: PropTypes.func.isRequired
};