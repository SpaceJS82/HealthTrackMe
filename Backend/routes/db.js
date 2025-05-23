// db.js
const knex = require('knex');
const config = require('./knexfile.js');

// Determine the environment, defaulting to 'development'
const env = process.env.NODE_ENV || 'development';

// Initialize Knex with the appropriate configuration
const db = knex(config[env]);

module.exports = db;
