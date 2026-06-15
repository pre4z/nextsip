import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(private readonly jwtService: JwtService) {}

  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader: string | undefined = request.headers['authorization'];

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('Manglende eller ugyldig token');
    }

    const token = authHeader.slice('Bearer '.length);

    try {
      // verificerer signature og ttl og soerger paa at payload ikke kan aendre sig paa vej hen
      request.user = this.jwtService.verify(token);
      return true;
    } catch {
      throw new UnauthorizedException('Ugyldig eller udloebet token');
    }
  }
}
