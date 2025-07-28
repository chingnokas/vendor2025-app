export interface User {
  id?: string;
  email: string;
  firstName?: string;
  lastName?: string;
  createdAt?: Date;
}

export interface LoginCredentials {
  email: string;
  password: string;
}

export interface SignupCredentials {
  firstName: string;
  lastName: string;
  email: string;
  password: string;
  confirmPassword: string;
}