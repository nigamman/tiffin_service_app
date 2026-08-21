import { Request, Response } from 'express';
import Order from '../models/Order';
import User from '../models/User';
import Coupon from '../models/Coupon';

export const getDashboardAnalytics = async (req: Request, res: Response) => {
  try {
    const totalCustomers = await User.countDocuments({ isAdmin: false });
    
    // Retrieve all successful transactions
    const paidOrders = await Order.find({ paymentStatus: 'paid' });
    const totalRevenue = paidOrders.reduce((sum, order) => sum + order.finalAmount, 0);

    // Filter today's stats
    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);
    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const todayOrders = paidOrders.filter(
      (order) => order.createdAt >= startOfToday && order.createdAt <= endOfToday
    );
    const todayOrdersCount = todayOrders.length;
    const todayRevenue = todayOrders.reduce((sum, order) => sum + order.finalAmount, 0);

    // Active recurring customer count
    const activeSubscribersCount = await Order.countDocuments({
      paymentStatus: 'paid',
      frequency: { $in: ['daily', 'weekly', 'monthly'] },
      orderStatus: 'confirmed'
    });

    // Coupon performance listing
    const coupons = await Coupon.find().sort({ usageCount: -1 }).limit(5);
    const couponStats = coupons.map((c) => ({
      code: c.code,
      usageCount: c.usageCount
    }));

    return res.status(200).json({
      totalCustomers,
      totalRevenue,
      todayOrdersCount,
      todayRevenue,
      activeSubscribersCount,
      couponStats
    });
  } catch (error) {
    console.error('Get analytics error:', error);
    return res.status(500).json({ message: 'Error retrieving analytics data' });
  }
};
