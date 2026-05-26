require('dotenv').config();
const mongoose = require('mongoose');

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/daurin';

console.log('Testing MongoDB connection to:', uri.startsWith('mongodb') ? uri.split('@').pop() : uri);

mongoose.set('strictQuery', true);

mongoose.connect(uri, { serverSelectionTimeoutMS: 20000, connectTimeoutMS: 20000 })
  .then(() => { console.log('Connected OK'); process.exit(0); })
  .catch(err => { console.error('Connect error:', err); process.exit(1); });
