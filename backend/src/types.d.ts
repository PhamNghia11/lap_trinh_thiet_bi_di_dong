declare module 'bcrypt' {
  export function hash(value: string, rounds: number): Promise<string>;
  export function compare(value: string, encrypted: string): Promise<boolean>;
}

declare module 'passport-jwt' {
  export const ExtractJwt: {
    fromAuthHeaderAsBearerToken(): (request: unknown) => string | null;
  };
  export class Strategy {
    constructor(options: unknown, verify?: unknown);
  }
}
