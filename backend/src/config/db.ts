import mongoose from 'mongoose';

export const connectDB = async (): Promise<void> => {
  const uri = process.env.MONGODB_URI;

  if (uri) {
    try {
      await mongoose.connect(uri);
      console.log('Successfully connected to MongoDB.');
    } catch (error) {
      console.error('Error connecting to MongoDB specified in MONGODB_URI:', error);
      console.log('Attempting to fall back to in-memory database...');
      await connectInMemoryDB();
    }
  } else {
    console.log('No MONGODB_URI found in environment config.');
    await connectInMemoryDB();
  }
};

const connectInMemoryDB = async (): Promise<void> => {
  try {
    // Dynamically import mongodb-memory-server to avoid importing it in production builds
    const { MongoMemoryServer } = require('mongodb-memory-server');
    const mongoServer = await MongoMemoryServer.create();
    const mongoUri = mongoServer.getUri();
    
    await mongoose.connect(mongoUri);
    console.log(`Connected to local in-memory MongoDB server at: ${mongoUri}`);
    console.log('Note: Data will be cleared when the server stops. Perfect for development!');
  } catch (error) {
    console.error('Failed to start/connect to local in-memory MongoDB:', error);
    process.exit(1);
  }
};
