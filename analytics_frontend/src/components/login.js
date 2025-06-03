import React, { useState } from 'react';
import PropTypes from 'prop-types';


async function loginUser(credentials) {
  const response = await fetch('http://localhost:1004/analytics/login/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(credentials)
  });
  if (!response.ok) {
    return {};
  }
  return response.json();
}

export default function Login({ setToken }) {
  const [username, setUserName] = useState('');
  const [password, setPassword] = useState('');
  const [validated, setValidated] = useState(false);

  const handleSubmit = async e => {
    e.preventDefault();
    setValidated(true);
    if (!username || !password) return;
    const data = await loginUser({ username, password });
    if (data.token) {
      setToken(data.token);
      sessionStorage.setItem('token', data.token);
    } else {
      alert('Login failed');
    }
  };

  return (
    <div className="login-wrapper d-flex justify-content-center align-items-center" style={{ minHeight: '100vh' }}>
      <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.6/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-4Q6Gf2aSP4eDXB8Miphtr37CMZZQ5oXLH2yaXMJ2w8e2ZtHTl7GptT4jmndRuHDT" crossOrigin="anonymous"></link>

      <form
        className={`row g-3 needs-validation ${validated ? 'was-validated' : ''}`}
        noValidate
        onSubmit={handleSubmit}
        style={{ maxWidth: 400, width: '100%', background: '#fff', padding: 32, borderRadius: 12, boxShadow: '0 2px 16px #0001' }}
      >
        <h1 className="mb-4 text-center">Please log in</h1>
        <div className="col-12">
          <label htmlFor="validationUsername" className="form-label">Username</label>
          <input
            type="text"
            className="form-control"
            id="validationUsername"
            value={username}
            onChange={e => setUserName(e.target.value)}
            required
          />
          <div className="invalid-feedback">
            Please enter your username.
          </div>
        </div>
        <div className="col-12">
          <label htmlFor="validationPassword" className="form-label">Password</label>
          <input
            type="password"
            className="form-control"
            id="validationPassword"
            value={password}
            onChange={e => setPassword(e.target.value)}
            required
          />
          <div className="invalid-feedback">
            Please enter your password.
          </div>
        </div>
        <div className="col-12">
          <button className="btn btn-primary w-100" type="submit">Login</button>
        </div>
      </form>
    </div>
  );
}

Login.propTypes = {
  setToken: PropTypes.func.isRequired
};