import mongoose, { Schema, Document } from 'mongoose';

export interface IDeliveryAddress {
  houseNo: string;
  area: string;
  landmark: string;
}

export interface IUser extends Document {
  phone: string;
  name: string;
  address?: IDeliveryAddress;
  isAdmin: boolean;
  createdAt: Date;
}

const UserSchema: Schema = new Schema({
  phone: { type: String, required: true, unique: true },
  name: { type: String, default: 'Tiffin Customer' },
  address: {
    houseNo: { type: String },
    area: { type: String },
    landmark: { type: String }
  },
  isAdmin: { type: Boolean, default: false },
  createdAt: { type: Date, default: Date.now }
});

export default mongoose.model<IUser>('User', UserSchema);
