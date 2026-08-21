import mongoose, { Schema, Document } from 'mongoose';

export interface ICoupon extends Document {
  code: string;
  discountType: 'fixed' | 'percent';
  discountValue: number;
  maxDiscount?: number; // Cap for percentage discounts
  minOrderValue: number;
  expiryDate?: Date;
  active: boolean;
  usageLimit?: number;
  usageCount: number;
  createdAt: Date;
}

const CouponSchema: Schema = new Schema({
  code: { type: String, required: true, unique: true, uppercase: true },
  discountType: { type: String, required: true, enum: ['fixed', 'percent'] },
  discountValue: { type: Number, required: true },
  maxDiscount: { type: Number },
  minOrderValue: { type: Number, default: 0 },
  expiryDate: { type: Date },
  active: { type: Boolean, default: true },
  usageLimit: { type: Number },
  usageCount: { type: Number, default: 0 },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model<ICoupon>('Coupon', CouponSchema);
