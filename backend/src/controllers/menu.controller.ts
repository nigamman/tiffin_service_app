import { Request, Response } from 'express';
import Menu from '../models/Menu';

// Default menu items to initialize if none exist
const DEFAULT_MENU_ITEMS = ['Dal Fry', 'Seasonal Sabzi', '4 Roti', 'Steamed Rice', 'Salad', 'Pickle'];
const DEFAULT_PRICE = 80;

export const getActiveMenu = async (req: Request, res: Response) => {
  try {
    let menu = await Menu.findOne({ isActive: true }).sort({ date: -1 });

    // Auto-create a default menu if database is empty to avoid blank screens
    if (!menu) {
      menu = await Menu.create({
        items: DEFAULT_MENU_ITEMS,
        price: DEFAULT_PRICE,
        imageUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
        isActive: true
      });
      console.log('No active menu found. Initialized default menu.');
    }

    return res.status(200).json({ menu });
  } catch (error) {
    console.error('Get active menu error:', error);
    return res.status(500).json({ message: 'Error retrieving menu' });
  }
};

export const updateMenu = async (req: Request, res: Response) => {
  try {
    const { items, price, imageUrl } = req.body;

    if (!items || !price) {
      return res.status(400).json({ message: 'Items and price are required' });
    }

    // Set all previous menus to inactive
    await Menu.updateMany({ isActive: true }, { isActive: false });

    // Create the new active menu
    const newMenu = await Menu.create({
      items,
      price,
      imageUrl: imageUrl || 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=500',
      isActive: true
    });

    return res.status(201).json({
      message: 'Menu updated successfully',
      menu: newMenu
    });
  } catch (error) {
    console.error('Update menu error:', error);
    return res.status(500).json({ message: 'Error updating menu' });
  }
};
