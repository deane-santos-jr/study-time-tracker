import jwt, { SignOptions } from 'jsonwebtoken';
import { jwtConfig } from '../config/jwt.config';

export interface TokenPayload {
  userId: string;
  email: string;
}

export class JWTService {
  generateToken(payload: TokenPayload): string {
    return jwt.sign(payload, jwtConfig.secret, {
      expiresIn: jwtConfig.expiresIn,
    } as SignOptions);
  }

  generateRefreshToken(payload: TokenPayload): string {
    return jwt.sign(payload, jwtConfig.refreshSecret, {
      expiresIn: jwtConfig.refreshExpiresIn,
    } as SignOptions);
  }

  verifyToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.verify(token, jwtConfig.secret) as TokenPayload;
      return decoded;
    } catch (error) {
      return null;
    }
  }

  verifyRefreshToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.verify(token, jwtConfig.refreshSecret) as TokenPayload;
      return decoded;
    } catch (error) {
      return null;
    }
  }

  decodeToken(token: string): TokenPayload | null {
    try {
      const decoded = jwt.decode(token) as TokenPayload;
      return decoded;
    } catch (error) {
      return null;
    }
  }
}
