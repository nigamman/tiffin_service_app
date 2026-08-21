import { Request, Response, NextFunction } from 'express';
import User, { IUser } from '../models/User';

export interface AuthRequest extends Request {
  user?: IUser;
}

export const authMiddleware = async (req: AuthRequest, res: Response, next: NextFunction) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No authorization token provided' });
    }

    const token = authHeader.split(' ')[1];

    if (!token) {
      return res.status(401).json({ message: 'Token is empty' });
    }

    // Mock Mode Auth: token format is "mock_phone_<phoneNumber>"
    if (token.startsWith('mock_phone_')) {
      const phone = token.replace('mock_phone_', '');
      
      let user = await User.findOne({ phone });
      if (!user) {
        // Automatically make specific phone numbers admin for testing
        const isAdmin = phone.endsWith('9999') || phone === '9876543210';
        user = await User.create({
          phone,
          name: `User ${phone.slice(-4)}`,
          isAdmin
        });
        console.log(`Created new mock user: ${phone} (Admin: ${isAdmin})`);
      }
      
      req.user = user;
      return next();
    }

    // Direct token database lookup for basic token validation
    let user = await User.findOne({ phone: token });
    if (!user) {
      // Create user if not exists
      user = await User.create({
        phone: token,
        name: `User ${token.slice(-4)}`,
        isAdmin: token.endsWith('9999') || token === '9876543210'
      });
    }

    req.user = user;
    return next();
  } catch (error) {
    console.error('Auth middleware error:', error);
    return res.status(500).json({ message: 'Server auth error' });
  }
};

export const adminMiddleware = (req: AuthRequest, res: Response, next: NextFunction) => {
  if (req.user && req.user.isAdmin) {
    next();
  } else {
    res.status(403).json({ message: 'Access denied: Admin only' });
  }
};
