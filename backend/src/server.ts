import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { connectDB } from './config/db';
import { seedCoupons } from './controllers/coupon.controller';

// Route imports
import authRoutes from './routes/auth.routes';
import menuRoutes from './routes/menu.routes';
import orderRoutes from './routes/order.routes';
import couponRoutes from './routes/coupon.routes';
import adminRoutes from './routes/admin.routes';

// Load environment variables
dotenv.config();

const app = express();
const port = process.env.PORT || 5000;

// Middleware
app.use(cors());
app.use(express.json());

// Basic welcome route
app.get('/', (req, res) => {
  res.json({
    message: 'Welcome to Kanpur Tiffin Service API MVP',
    status: 'online',
    time: new Date()
  });
});

// Register API routes
app.use('/api/auth', authRoutes);
app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/coupons', couponRoutes);
app.use('/api/admin', adminRoutes);

// Start server function
const startServer = async () => {
  try {
    // 1. Connect to Database (real Mongo or memory-server fallback)
    await connectDB();

    // 2. Pre-seed coupons if empty
    await seedCoupons();

    // 3. Start listening
    app.listen(port, () => {
      console.log(`=============================================`);
      console.log(` Kanpur Tiffin API Server running on port ${port} `);
      console.log(` Environment: ${process.env.NODE_ENV || 'development'} `);
      console.log(`=============================================`);
    });
  } catch (error) {
    console.error('Fatal error starting tiffin server:', error);
    process.exit(1);
  }
};

startServer();
