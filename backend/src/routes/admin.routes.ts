import { Router } from 'express';
import { getDashboardAnalytics } from '../controllers/analytics.controller';
import { adminGetOrders, adminUpdateOrderStatus } from '../controllers/order.controller';
import { authMiddleware, adminMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);
router.use(adminMiddleware);

router.get('/analytics', getDashboardAnalytics);
router.get('/orders', adminGetOrders);
router.put('/orders/:orderId/status', adminUpdateOrderStatus);

export default router;
