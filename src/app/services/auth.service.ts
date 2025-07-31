import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { BehaviorSubject, Observable } from 'rxjs';
import { map, catchError } from 'rxjs/operators';
import { of } from 'rxjs';
import { User, LoginCredentials, SignupCredentials } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();
  private apiUrl = 'http://localhost:3002/api'; // Docker Compose backend port

  constructor(private http: HttpClient) {
    const savedUser = localStorage.getItem('currentUser');
    if (savedUser) {
      this.currentUserSubject.next(JSON.parse(savedUser));
    }
  }

  signup(credentials: SignupCredentials): Observable<{ success: boolean; message?: string; user?: User }> {
    console.log('🚀 Making signup request to:', `${this.apiUrl}/auth/register`);
    console.log('📤 Signup payload:', {
      email: credentials.email,
      name: `${credentials.firstName} ${credentials.lastName}`,
      role: 'user'
    });

    return this.http.post<any>(`${this.apiUrl}/auth/register`, {
      email: credentials.email,
      password: credentials.password,
      name: `${credentials.firstName} ${credentials.lastName}`,
      role: 'user'
    }).pipe(
      map((response: any) => {
        console.log('✅ Signup response received:', response);

        if (response.token) {
          const user: User = {
            id: response.userId.toString(),
            email: credentials.email,
            firstName: credentials.firstName,
            lastName: credentials.lastName,
            createdAt: new Date()
          };

          localStorage.setItem('currentUser', JSON.stringify(user));
          this.currentUserSubject.next(user);

          console.log('👤 User created and stored:', user);
          return { success: true, user };
        }
        return { success: false, message: response.message || 'Registration failed' };
      }),
      catchError((error: any) => {
        console.error('❌ Signup error details:', error);
        console.error('📊 Error status:', error.status);
        console.error('📝 Error message:', error.message);
        console.error('🔍 Full error object:', error);

        let errorMessage = 'Registration failed. Please try again.';
        if (error.error?.message) {
          errorMessage = error.error.message;
        } else if (error.status === 0) {
          errorMessage = 'Cannot connect to server. Please check if the backend is running.';
        }

        return of({ success: false, message: errorMessage });
      })
    );
  }

  login(credentials: LoginCredentials): Observable<{ success: boolean; message?: string; user?: User }> {
    console.log('🔐 Making login request to:', `${this.apiUrl}/auth/login`);
    console.log('📤 Login payload:', { email: credentials.email });

    return this.http.post<any>(`${this.apiUrl}/auth/login`, {
      email: credentials.email,
      password: credentials.password
    }).pipe(
      map((response: any) => {
        console.log('✅ Login response received:', response);

        if (response.token) {
          const user: User = {
            id: response.userId.toString(),
            email: credentials.email,
            firstName: 'User',
            lastName: 'Name',
            createdAt: new Date()
          };

          localStorage.setItem('currentUser', JSON.stringify(user));
          this.currentUserSubject.next(user);

          console.log('👤 User logged in and stored:', user);
          return { success: true, user };
        }
        return { success: false, message: response.message || 'Login failed' };
      }),
      catchError((error: any) => {
        console.error('❌ Login error details:', error);
        console.error('📊 Error status:', error.status);
        console.error('📝 Error message:', error.message);

        let errorMessage = 'Login failed. Please try again.';
        if (error.error?.message) {
          errorMessage = error.error.message;
        } else if (error.status === 0) {
          errorMessage = 'Cannot connect to server. Please check if the backend is running.';
        }

        return of({ success: false, message: errorMessage });
      })
    );
  }

  logout(): void {
    localStorage.removeItem('currentUser');
    this.currentUserSubject.next(null);
  }

  get currentUserValue(): User | null {
    return this.currentUserSubject.value;
  }

  isAuthenticated(): boolean {
    return !!this.currentUserValue;
  }
}
