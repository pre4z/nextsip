import { Injectable, UnauthorizedException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';

@Injectable()
export class AuthService {
  constructor(
    private readonly jwtService: JwtService,
    private readonly config: ConfigService,
  ) {}

  login(username: string, password: string): { access_token: string } {
    const adminUsername = this.config.get<string>('ADMIN_USERNAME');
    const adminPassword = this.config.get<string>('ADMIN_PASSWORD');

    if (username !== adminUsername || password !== adminPassword) {
      throw new UnauthorizedException('Forkert brugernavn eller adgangskode');
    }

    // JWT payload
    const payload = { username, role: 'admin' };

    return { access_token: this.jwtService.sign(payload) };
  }
}
