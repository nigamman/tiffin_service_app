import { Router } from 'express';
import { validateCoupon, getCoupons, createCoupon, toggleCouponStatus } from '../controllers/coupon.controller';
import { authMiddleware, adminMiddleware } from '../middleware/auth';

const router = Router();

router.post('/validate', authMiddleware, validateCoupon);
router.get('/', authMiddleware, getCoupons);
router.post('/', authMiddleware, adminMiddleware, createCoupon);
router.put('/:id/toggle', authMiddleware, adminMiddleware, toggleCouponStatus);

export default router;
