import { Router } from 'express';
import { createOrder, verifyPayment, getUserOrders, skipDeliveryDate } from '../controllers/order.controller';
import { authMiddleware } from '../middleware/auth';

const router = Router();

router.use(authMiddleware);

router.post('/', createOrder);
router.post('/verify', verifyPayment);
router.get('/my-orders', getUserOrders);
router.post('/skip', skipDeliveryDate);

export default router;
