import { Request, Response } from 'express';
import Coupon from '../models/Coupon';

export const seedCoupons = async () => {
  try {
    const count = await Coupon.countDocuments();
    if (count === 0) {
      await Coupon.create([
        {
          code: 'FIRSTTIFFIN',
          discountType: 'fixed',
          discountValue: 30,
          minOrderValue: 80,
          active: true
        },
        {
          code: 'KANPUR50',
          discountType: 'fixed',
          discountValue: 50,
          minOrderValue: 200,
          active: true
        },
        {
          code: 'WELCOME20',
          discountType: 'percent',
          discountValue: 20,
          maxDiscount: 100,
          minOrderValue: 80,
          active: true
        },
        {
          code: 'WEEKLY50',
          discountType: 'fixed',
          discountValue: 50,
          minOrderValue: 500,
          active: true
        }
      ]);
      console.log('Pre-seeded default coupons: FIRSTTIFFIN, KANPUR50, WELCOME20, WEEKLY50');
    }
  } catch (error) {
    console.error('Error seeding coupons:', error);
  }
};

export const validateCoupon = async (req: Request, res: Response) => {
  try {
    const { code, orderValue } = req.body;

    if (!code || orderValue === undefined) {
      return res.status(400).json({ message: 'Coupon code and order value are required' });
    }

    const coupon = await Coupon.findOne({ code: code.toUpperCase() });

    if (!coupon) {
      return res.status(404).json({ isValid: false, message: 'Invalid coupon code' });
    }

    if (!coupon.active) {
      return res.status(400).json({ isValid: false, message: 'This coupon is no longer active' });
    }

    if (coupon.expiryDate && new Date(coupon.expiryDate) < new Date()) {
      return res.status(400).json({ isValid: false, message: 'This coupon has expired' });
    }

    if (coupon.usageLimit && coupon.usageCount >= coupon.usageLimit) {
      return res.status(400).json({ isValid: false, message: 'This coupon usage limit has been reached' });
    }

    if (orderValue < coupon.minOrderValue) {
      return res.status(400).json({ 
        isValid: false, 
        message: `Minimum order value of ₹${coupon.minOrderValue} required for this coupon` 
      });
    }

    // Calculate discount
    let discount = 0;
    if (coupon.discountType === 'fixed') {
      discount = coupon.discountValue;
    } else if (coupon.discountType === 'percent') {
      discount = (orderValue * coupon.discountValue) / 100;
      if (coupon.maxDiscount && discount > coupon.maxDiscount) {
        discount = coupon.maxDiscount;
      }
    }

    // Round discount to nearest integer
    discount = Math.round(discount);

    // Make sure discount is not more than the order value
    discount = Math.min(discount, orderValue);

    return res.status(200).json({
      isValid: true,
      code: coupon.code,
      discountType: coupon.discountType,
      discountValue: coupon.discountValue,
      discountAmount: discount,
      message: 'Coupon applied successfully!'
    });
  } catch (error) {
    console.error('Validate coupon error:', error);
    return res.status(500).json({ message: 'Error validating coupon' });
  }
};

export const getCoupons = async (req: Request, res: Response) => {
  try {
    const coupons = await Coupon.find().sort({ createdAt: -1 });
    return res.status(200).json({ coupons });
  } catch (error) {
    console.error('Get coupons error:', error);
    return res.status(500).json({ message: 'Error fetching coupons' });
  }
};

export const createCoupon = async (req: Request, res: Response) => {
  try {
    const { code, discountType, discountValue, maxDiscount, minOrderValue, expiryDate, usageLimit } = req.body;

    if (!code || !discountType || discountValue === undefined) {
      return res.status(400).json({ message: 'Code, discount type, and discount value are required' });
    }

    const existing = await Coupon.findOne({ code: code.toUpperCase() });
    if (existing) {
      return res.status(400).json({ message: 'A coupon with this code already exists' });
    }

    const coupon = await Coupon.create({
      code: code.toUpperCase(),
      discountType,
      discountValue,
      maxDiscount,
      minOrderValue: minOrderValue || 0,
      expiryDate,
      usageLimit,
      active: true
    });

    return res.status(201).json({
      message: 'Coupon created successfully',
      coupon
    });
  } catch (error) {
    console.error('Create coupon error:', error);
    return res.status(500).json({ message: 'Error creating coupon' });
  }
};

export const toggleCouponStatus = async (req: Request, res: Response) => {
  try {
    const { id } = req.params;
    const coupon = await Coupon.findById(id);

    if (!coupon) {
      return res.status(404).json({ message: 'Coupon not found' });
    }

    coupon.active = !coupon.active;
    await coupon.save();

    return res.status(200).json({
      message: `Coupon ${coupon.active ? 'activated' : 'deactivated'} successfully`,
      coupon
    });
  } catch (error) {
    console.error('Toggle coupon status error:', error);
    return res.status(500).json({ message: 'Error toggling coupon status' });
  }
};
