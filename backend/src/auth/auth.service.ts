import {
  BadRequestException,
  ConflictException,
  InternalServerErrorException,
  Injectable,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { GoogleLoginDto } from './dto/google-login.dto';
import { User, UserDocument } from './schemas/user.schema';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name)
    private readonly userModel: Model<UserDocument>,
  ) {}

  async register(registerDto: RegisterDto) {
    try {
      const normalizedEmail = registerDto.email.trim().toLowerCase();
      const normalizedUsername = registerDto.username.trim().toLowerCase();

      const existingUser = await this.userModel
        .findOne({
          $or: [{ email: normalizedEmail }, { username: normalizedUsername }],
        })
        .exec();

      if (existingUser) {
        if (existingUser.email === normalizedEmail) {
          throw new ConflictException('Email already registered');
        }
        throw new ConflictException('Username already taken');
      }

      const user = await this.userModel.create({
        ...registerDto,
        email: normalizedEmail,
        username: normalizedUsername,
      });

      return {
        message: 'Registration successful',
        user: {
          id: user._id,
          username: user.username,
          email: user.email,
          phoneNumber: user.phoneNumber,
        },
      };
    } catch (error) {
      throw this.mapDbError(error);
    }
  }

  async login(loginDto: LoginDto) {
    try {
      const rawIdentifier = loginDto.identifier ?? loginDto.email;
      if (!rawIdentifier || rawIdentifier.trim() === '') {
        throw new BadRequestException('identifier or email is required');
      }

      const normalizedIdentifier = rawIdentifier.trim().toLowerCase();

      const user = await this.userModel
        .findOne({
          $or: [
            { email: normalizedIdentifier },
            { username: normalizedIdentifier },
          ],
        })
        .exec();

      if (!user) {
        throw new NotFoundException(
          'Account not found. Please register first (email/username).',
        );
      }

      if (user.password !== loginDto.password) {
        throw new UnauthorizedException('Wrong password');
      }

      return {
        message: 'Login successful',
        user: {
          id: user._id,
          username: user.username,
          email: user.email,
          phoneNumber: user.phoneNumber,
        },
      };
    } catch (error) {
      throw this.mapDbError(error);
    }
  }

  async googleLogin(googleLoginDto: GoogleLoginDto) {
    try {
      const email = googleLoginDto.email.trim().toLowerCase();
      if (!email) {
        throw new BadRequestException('Email diperlukan untuk Google login');
      }

      const normalizedDisplayName = googleLoginDto.displayName
        ?.trim()
        .toLowerCase();

      let user = await this.userModel.findOne({ email }).exec();
      if (user) {
        return {
          message: 'Login Google berhasil',
          user: {
            id: user._id,
            username: user.username,
            email: user.email,
            phoneNumber: user.phoneNumber,
          },
        };
      }

      const username = await this.generateUniqueUsername(
        normalizedDisplayName?.replace(/\s+/g, '') ||
          email.split('@')[0],
      );
      const randomPassword = Math.random().toString(36).slice(2, 12);

      user = await this.userModel.create({
        username,
        email,
        phoneNumber: '',
        password: randomPassword,
      });

      return {
        message: 'Login Google berhasil',
        user: {
          id: user._id,
          username: user.username,
          email: user.email,
          phoneNumber: user.phoneNumber,
        },
      };
    } catch (error) {
      throw this.mapDbError(error);
    }
  }

  private async generateUniqueUsername(base: string) {
    const sanitizedBase = base
      .replace(/[^a-z0-9]/g, '')
      .trim()
      .toLowerCase();
    let candidate = sanitizedBase.length > 0 ? sanitizedBase : `user${Date.now()}`;
    let suffix = '';

    while (
      await this.userModel.exists({ username: `${candidate}${suffix}` })
    ) {
      suffix = Math.floor(Math.random() * 9000 + 1000).toString();
    }

    return `${candidate}${suffix}`;
  }

  private mapDbError(error: unknown) {
    if (
      error instanceof BadRequestException ||
      error instanceof ConflictException ||
      error instanceof NotFoundException ||
      error instanceof UnauthorizedException
    ) {
      return error;
    }

    if (error instanceof Error) {
      const message = error.message.toLowerCase();
      if (
        message.includes('buffering timed out') ||
        message.includes('server selection timed out') ||
        message.includes('topology is closed') ||
        message.includes('econnrefused')
      ) {
        return new ServiceUnavailableException(
          'Database unavailable. Pastikan MongoDB berjalan.',
        );
      }
    }

    return new InternalServerErrorException('Internal server error');
  }
}
