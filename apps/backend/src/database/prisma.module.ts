import { Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

/**
 * PrismaModule provides the Prisma client as a shared service.
 * Exports PrismaService for use throughout the application.
 */
@Module({
  providers: [PrismaService],
  exports: [PrismaService],
})
export class PrismaModule {}
