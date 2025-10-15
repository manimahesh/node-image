// server.js

const express = require('express');
const app = express();
const port = 80;

const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database(':memory:');

// Route handler for the root path ("/")
app.get('/', (req, res) => {
    // Send the "Hello World!" text as the response
    res.send('Hello World! 👋');
});

// Start the server
app.listen(port, () => {
    console.log(`Hello there. The server is running at http://localhost:${port}`);
});
