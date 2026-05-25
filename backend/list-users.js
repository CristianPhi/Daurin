require('dotenv').config();
const mongoose = require('mongoose');

const uri = process.env.MONGODB_URI || 'mongodb://localhost:27017/daurin';

async function main(){
  try{
    await mongoose.connect(uri, { serverSelectionTimeoutMS: 20000, connectTimeoutMS: 20000 });
    console.log('Connected to MongoDB — listing users...');
    const users = await mongoose.connection.db.collection('users').find({}, { projection: { email: 1, username:1, password:1, pin:1 } }).toArray();
    if(users.length === 0){
      console.log('No users found');
    } else {
      users.forEach(u => {
        console.log(JSON.stringify(u));
      });
    }
    process.exit(0);
  }catch(err){
    console.error('Error:', err);
    process.exit(1);
  }
}

main();
