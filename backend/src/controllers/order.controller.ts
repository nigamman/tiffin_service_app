import { Response } from 'express';
import { AuthRequest } from '../middleware/auth';
import Order, { TiffinFrequency, PaymentStatus, OrderStatus } from '../models/Order';
import Menu from '../models/Menu';
import Coupon from '../models/Coupon';
import Payment from '../models/Payment';
import crypto from 'crypto';

// Helper to determine meal count for frequency
const getMealsCount = (frequency: TiffinFrequency): number => {
  switch (frequency) {
    case 'one-time': return 1;
    case 'daily': return 7; // standard recurring daily delivery (7 meals initially booked)
    case 'weekly': return 7;
    case 'monthly': return 30;
    default: return 1;
  }
};

export const createOrder = async (req: AuthRequest, res: Response) => {
  try {
    const {
      frequency,
      quantity,
      startDate,
      deliverySlot,
      deliveryAddress,
      contactPhone,
      couponCode
    } = req.body;

    if (!frequency || !quantity || !startDate || !deliverySlot || !deliveryAddress || !contactPhone) {
      return res.status(400).json({ message: 'Missing required order fields' });
    }

    if (!req.user) {
      return res.status(401).json({ message: 'User not authenticated' });
    }

    // 1. Fetch active menu to get current meal price
    const menu = await Menu.findOne({ isActive: true }).sort({ date: -1 });
    if (!menu) {
      return res.status(404).json({ message: 'No active menu available today' });
    }

    // 2. Pricing calculations
    const pricePerMeal = menu.price;
    const mealsCount = getMealsCount(frequency);
    const totalAmount = pricePerMeal * mealsCount * quantity;

    let discountAmount = 0;

    // 3. Verify Coupon if supplied
    if (couponCode) {
      const coupon = await Coupon.findOne({ code: couponCode.toUpperCase(), active: true });
      if (coupon) {
        // Validate coupon rules
        const matchesMinOrder = totalAmount >= coupon.minOrderValue;
        const matchesExpiry = !coupon.expiryDate || new Date(coupon.expiryDate) > new Date();
        const matchesLimit = !coupon.usageLimit || coupon.usageCount < coupon.usageLimit;

        if (matchesMinOrder && matchesExpiry && matchesLimit) {
          if (coupon.discountType === 'fixed') {
            discountAmount = coupon.discountValue;
          } else if (coupon.discountType === 'percent') {
            discountAmount = (totalAmount * coupon.discountValue) / 100;
            if (coupon.maxDiscount && discountAmount > coupon.maxDiscount) {
              discountAmount = coupon.maxDiscount;
            }
          }
          discountAmount = Math.round(discountAmount);
          discountAmount = Math.min(discountAmount, totalAmount);
        }
      }
    }

    const finalAmount = totalAmount - discountAmount;

    // 4. Create pending order in database
    const order = new Order({
      user: req.user._id,
      menu: menu._id,
      frequency,
      quantity,
      startDate: new Date(startDate),
      deliverySlot,
      deliveryAddress,
      contactPhone,
      pricePerMeal,
      mealsCount,
      totalAmount,
      discountAmount,
      finalAmount,
      couponCode: couponCode ? couponCode.toUpperCase() : undefined,
      paymentStatus: 'pending',
      orderStatus: 'confirmed', // Confirmed after payment triggers
      skippedDates: []
    });

    // 5. Generate Razorpay Order ID (Mock or real)
    const keyId = process.env.RAZORPAY_KEY_ID || 'rzp_test_mockkey1234';
    let razorpayOrderId = '';

    if (keyId.startsWith('rzp_test_mock')) {
      // Mock mode
      razorpayOrderId = `order_mock_${Math.random().toString(36).substring(2, 15)}`;
    } else {
      // Real Razorpay connection (Optional setup)
      try {
        const Razorpay = require('razorpay');
        const rzp = new Razorpay({
          key_id: process.env.RAZORPAY_KEY_ID,
          key_secret: process.env.RAZORPAY_KEY_SECRET
        });
        const rzpOrder = await rzp.orders.create({
          amount: finalAmount * 100, // Razorpay works in paise
          currency: 'INR',
          receipt: order._id.toString()
        });
        razorpayOrderId = rzpOrder.id;
      } catch (error) {
        console.error('Razorpay SDK creation failed, falling back to mock Razorpay order ID:', error);
        razorpayOrderId = `order_mock_fallback_${Math.random().toString(36).substring(2, 15)}`;
      }
    }

    order.razorpayOrderId = razorpayOrderId;
    await order.save();

    // 6. Create payment record
    await Payment.create({
      orderId: order._id,
      razorpayOrderId,
      amount: finalAmount,
      status: 'created'
    });

    return res.status(201).json({
      message: 'Order created successfully',
      orderId: order._id,
      razorpayOrderId,
      amount: finalAmount,
      keyId
    });
  } catch (error) {
    console.error('Create order error:', error);
    return res.status(500).json({ message: 'Error placing order' });
  }
};

export const verifyPayment = async (req: AuthRequest, res: Response) => {
  try {
    const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = req.body;

    if (!orderId || !razorpayOrderId || !razorpayPaymentId) {
      return res.status(400).json({ message: 'Missing payment details' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Verify order ID matches razorpay order ID
    if (order.razorpayOrderId !== razorpayOrderId) {
      return res.status(400).json({ message: 'Razorpay order ID mismatch' });
    }

    const keySecret = process.env.RAZORPAY_KEY_SECRET || 'mocksecret1234567890';
    let isSignatureValid = false;

    // Check if mock mode is active
    if (razorpayOrderId.startsWith('order_mock') || keySecret === 'mocksecret1234567890') {
      isSignatureValid = true; // Automatically validate mock payments
      console.log(`Mock payment verified for order ${orderId}`);
    } else {
      // Real cryptographic verification
      if (!razorpaySignature) {
        return res.status(400).json({ message: 'Payment signature required for live accounts' });
      }
      const text = `${razorpayOrderId}|${razorpayPaymentId}`;
      const generated_signature = crypto
        .createHmac('sha256', keySecret)
        .update(text)
        .digest('hex');

      isSignatureValid = generated_signature === razorpaySignature;
    }

    if (!isSignatureValid) {
      order.paymentStatus = 'failed';
      await order.save();
      await Payment.findOneAndUpdate(
        { orderId },
        { razorpayPaymentId, razorpaySignature, status: 'failed' }
      );
      return res.status(400).json({ verified: false, message: 'Invalid payment signature' });
    }

    // Update order status
    order.paymentStatus = 'paid';
    order.razorpayPaymentId = razorpayPaymentId;
    await order.save();

    // Update payment record
    await Payment.findOneAndUpdate(
      { orderId },
      { razorpayPaymentId, razorpaySignature, status: 'captured' }
    );

    // Update coupon usage count if applied
    if (order.couponCode) {
      await Coupon.findOneAndUpdate(
        { code: order.couponCode },
        { $inc: { usageCount: 1 } }
      );
    }

    return res.status(200).json({
      verified: true,
      message: 'Payment verified and order confirmed!',
      order
    });
  } catch (error) {
    console.error('Verify payment error:', error);
    return res.status(500).json({ message: 'Error verifying payment status' });
  }
};

export const getUserOrders = async (req: AuthRequest, res: Response) => {
  try {
    if (!req.user) {
      return res.status(401).json({ message: 'Unauthorized' });
    }

    const orders = await Order.find({ user: req.user._id, paymentStatus: 'paid' })
      .populate('menu')
      .sort({ createdAt: -1 });

    return res.status(200).json({ orders });
  } catch (error) {
    console.error('Get user orders error:', error);
    return res.status(500).json({ message: 'Error fetching user orders' });
  }
};

export const skipDeliveryDate = async (req: AuthRequest, res: Response) => {
  try {
    const { orderId, date } = req.body;

    if (!orderId || !date) {
      return res.status(400).json({ message: 'Order ID and skip date are required' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    // Verify ownership
    if (order.user.toString() !== req.user?._id.toString()) {
      return res.status(403).json({ message: 'Unauthorized access to this order' });
    }

    const skipDate = new Date(date);
    // Normalize date to remove time details
    skipDate.setHours(0, 0, 0, 0);

    // Check if already skipped
    const alreadySkipped = order.skippedDates.some(
      (d) => new Date(d).getTime() === skipDate.getTime()
    );

    if (alreadySkipped) {
      return res.status(400).json({ message: 'This date is already marked as skipped' });
    }

    order.skippedDates.push(skipDate);
    await order.save();

    return res.status(200).json({
      message: 'Tiffin skipped successfully for ' + skipDate.toLocaleDateString(),
      order
    });
  } catch (error) {
    console.error('Skip delivery date error:', error);
    return res.status(500).json({ message: 'Error skipping delivery' });
  }
};

export const adminGetOrders = async (req: Request, res: Response) => {
  try {
    const { filter } = req.query; // 'today', 'tomorrow', 'upcoming', 'all'
    const query: any = { paymentStatus: 'paid' };

    const startOfToday = new Date();
    startOfToday.setHours(0, 0, 0, 0);

    const endOfToday = new Date();
    endOfToday.setHours(23, 59, 59, 999);

    const startOfTomorrow = new Date(startOfToday);
    startOfTomorrow.setDate(startOfTomorrow.getDate() + 1);

    const endOfTomorrow = new Date(endOfToday);
    endOfTomorrow.setDate(endOfTomorrow.getDate() + 1);

    if (filter === 'today') {
      query.startDate = { $lte: endOfToday };
      // Keep only orders that have not expired (for subscriptions)
      // For MVP simplicity, we pull orders starting today or active sub orders
    } else if (filter === 'tomorrow') {
      query.startDate = { $lte: endOfTomorrow };
    }

    const orders = await Order.find(query)
      .populate('user')
      .populate('menu')
      .sort({ createdAt: -1 });

    return res.status(200).json({ orders });
  } catch (error) {
    console.error('Admin get orders error:', error);
    return res.status(500).json({ message: 'Error fetching orders list' });
  }
};

export const adminUpdateOrderStatus = async (req: Request, res: Response) => {
  try {
    const { orderId } = req.params;
    const { orderStatus } = req.body;

    if (!orderStatus) {
      return res.status(400).json({ message: 'Order status is required' });
    }

    const order = await Order.findById(orderId);
    if (!order) {
      return res.status(404).json({ message: 'Order not found' });
    }

    order.orderStatus = orderStatus;
    await order.save();

    return res.status(200).json({
      message: 'Order status updated successfully',
      order
    });
  } catch (error) {
    console.error('Admin update status error:', error);
    return res.status(500).json({ message: 'Error updating order status' });
  }
};
