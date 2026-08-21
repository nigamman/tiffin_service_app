import mongoose, { Schema, Document } from 'mongoose';

export interface IMenu extends Document {
  items: string[];
  price: number;
  imageUrl: string;
  isActive: boolean;
  date: Date;
}

const MenuSchema: Schema = new Schema({
  items: { type: [String], required: true },
  price: { type: Number, required: true, default: 80 },
  imageUrl: { type: String, default: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500' }, // premium food placeholder
  isActive: { type: Boolean, default: true },
  date: { type: Date, default: Date.now }
});

export default mongoose.model<IMenu>('Menu', MenuSchema);
