import { Router } from 'express';
import { getActiveMenu, updateMenu } from '../controllers/menu.controller';
import { authMiddleware, adminMiddleware } from '../middleware/auth';

const router = Router();

router.get('/', getActiveMenu);
router.post('/', authMiddleware, adminMiddleware, updateMenu);

export default router;
