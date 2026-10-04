const express = require('express');
const cors = require('cors');
require('dotenv').config();

const app = express();

app.use(cors());
app.use(express.json());

// Test route
app.get('/', (req, res) => {
  res.json({ message: 'Telemedicine Chatbot API is running ✓' });
});

// Routes
app.use('/api/auth',         require('./routes/auth'));
app.use('/api/consultation', require('./routes/consultation'));
app.use('/api/records',      require('./routes/records'));
app.use('/api/admin',        require('./routes/admin'));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});