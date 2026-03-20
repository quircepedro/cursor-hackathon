// FirebaseModule is @Global() and imported in AppModule — do NOT re-import it here.
// FirebaseService is available application-wide. UsersModule must be imported explicitly.
import { Module } from '@nestjs/common';
import { UsersModule } from '../users/users.module';
import { AuthController } from './controllers/auth.controller';
import { AuthService } from './services/auth.service';
import { FirebaseAuthGuard } from './guards/firebase-auth.guard';

@Module({
  imports: [UsersModule],
  controllers: [AuthController],
  providers: [AuthService, FirebaseAuthGuard],
  exports: [FirebaseAuthGuard],
})
export class AuthModule {}
