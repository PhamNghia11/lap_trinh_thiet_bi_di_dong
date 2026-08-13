import { validate } from 'class-validator';
import {
  ChangePasswordDto,
  LoginDto,
  RegisterDto,
  ResetPasswordDto,
} from './auth.dto';

describe('Auth DTO limits', () => {
  it('rejects passwords longer than bcrypt safely handles', async () => {
    const register = Object.assign(new RegisterDto(), {
      email: 'user@example.com',
      password: 'a'.repeat(73),
      fullName: 'FLIX User',
    });
    const login = Object.assign(new LoginDto(), {
      email: 'user@example.com',
      password: 'a'.repeat(73),
    });
    const change = Object.assign(new ChangePasswordDto(), {
      currentPassword: 'a'.repeat(73),
      newPassword: 'b'.repeat(73),
    });

    expect(await validate(register)).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ property: 'password' }),
      ]),
    );
    expect(await validate(login)).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ property: 'password' }),
      ]),
    );
    expect(await validate(change)).toHaveLength(2);
  });

  it('requires an exact six-character reset code', async () => {
    const reset = Object.assign(new ResetPasswordDto(), {
      email: 'user@example.com',
      code: '1234567',
      newPassword: 'new-password',
    });

    expect(await validate(reset)).toEqual(
      expect.arrayContaining([expect.objectContaining({ property: 'code' })]),
    );
  });

  it('accepts normal authentication payloads', async () => {
    const register = Object.assign(new RegisterDto(), {
      email: 'user@example.com',
      password: 'strong-password',
      fullName: 'FLIX User',
    });

    await expect(validate(register)).resolves.toEqual([]);
  });
});
