import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { compare, hash } from 'bcrypt';
import { PrismaService } from '../prisma/prisma.service';
import { LoginDto, RegisterDto } from './auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const email = dto.email.trim().toLowerCase();
    if (await this.prisma.user.findUnique({ where: { email } })) {
      throw new ConflictException('Email đã được sử dụng');
    }
    const user = await this.prisma.user.create({
      data: {
        email,
        fullName: dto.fullName?.trim(),
        passwordHash: await hash(dto.password, 12),
      },
      select: { id: true, email: true, fullName: true, avatarUrl: true },
    });
    return {
      user,
      accessToken: await this.jwt.signAsync({
        sub: user.id,
        email: user.email,
      }),
    };
  }

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email.trim().toLowerCase() },
    });
    if (!user || !(await compare(dto.password, user.passwordHash))) {
      throw new UnauthorizedException('Email hoặc mật khẩu không đúng');
    }
    return {
      user: {
        id: user.id,
        email: user.email,
        fullName: user.fullName,
        avatarUrl: user.avatarUrl,
      },
      accessToken: await this.jwt.signAsync({
        sub: user.id,
        email: user.email,
      }),
    };
  }
}
