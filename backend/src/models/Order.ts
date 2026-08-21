import mongoose, { Schema, Document } from 'mongoose';
import { IDeliveryAddress } from './User';

export type TiffinFrequency = 'one-time' | 'daily' | 'weekly' | 'monthly';
export type PaymentStatus = 'pending' | 'paid' | 'failed';
export type OrderStatus = 'confirmed' | 'cancelled';
export type DeliveryStatus = 'pending' | 'preparing' | 'out-for-delivery' | 'delivered';

export interface IOrder extends Document {
  user: mongoose.Types.ObjectId;
  menu: mongoose.Types.ObjectId;
  frequency: TiffinFrequency;
  quantity: number;
  startDate: Date;
  deliverySlot: 'lunch' | 'dinner';
  deliveryAddress: IDeliveryAddress;
  contactPhone: string;
  pricePerMeal: number;
  mealsCount: number;
  totalAmount: number;
  discountAmount: number;
  finalAmount: number;
  couponCode?: string;
  paymentStatus: PaymentStatus;
  orderStatus: OrderStatus;
  razorpayOrderId?: string;
  razorpayPaymentId?: string;
  skippedDates: Date[]; // Dates that are skipped by the user
  createdAt: Date;
}

const OrderSchema: Schema = new Schema({
  user: { type: Schema.Types.ObjectId, ref: 'User', required: true },
  menu: { type: Schema.Types.ObjectId, ref: 'Menu', required: true },
  frequency: { type: String, required: true, enum: ['one-time', 'daily', 'weekly', 'monthly'] },
  quantity: { type: Number, required: true, default: 1 },
  startDate: { type: Date, required: true },
  deliverySlot: { type: String, required: true, enum: ['lunch', 'dinner'], default: 'lunch' },
  deliveryAddress: {
    houseNo: { type: String, required: true },
    area: { type: String, required: true },
    landmark: { type: String, required: true }
  },
  contactPhone: { type: String, required: true },
  pricePerMeal: { type: Number, required: true },
  mealsCount: { type: Number, required: true },
  totalAmount: { type: Number, required: true },
  discountAmount: { type: Number, default: 0 },
  finalAmount: { type: Number, required: true },
  couponCode: { type: String },
  paymentStatus: { type: String, required: true, enum: ['pending', 'paid', 'failed'], default: 'pending' },
  orderStatus: { type: String, required: true, enum: ['confirmed', 'cancelled'], default: 'confirmed' },
  razorpayOrderId: { type: String },
  razorpayPaymentId: { type: String },
  skippedDates: [{ type: Date }],
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model<IOrder>('Order', OrderSchema);
