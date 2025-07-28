import { Injectable } from '@angular/core';
import { BehaviorSubject, Observable, of } from 'rxjs';
import { delay, map } from 'rxjs/operators';
import { User, LoginCredentials, SignupCredentials } from '../models/user.model';

@Injectable({
  providedIn: 'root'
})
export class AuthService {
  private currentUserSubject = new BehaviorSubject<User | null>(null);
  public currentUser$ = this.currentUserSubject.asObservable();

  constructor() {
    // Check if user is already logged in (from localStorage)
    const savedUser = localStorage.getItem('currentUser');
    if (savedUser) {
      this.currentUserSubject.next(JSON.parse(savedUser));
    }
  }

  login(credentials: LoginCredentials): Observable<{ success: boolean; message?: string; user?: User }> {
    // Simulate API call
    return of(null).pipe(
      delay(1000),
      map(() => {
        // Simple validation for demo
        if (credentials.email === 'demo@example.com' && credentials.password === 'password') {
          const user: User = {
            id: '1',
            email: credentials.email,
            firstName: 'Demo',
            lastName: 'User',
            createdAt: new Date()
          };
          
          localStorage.setItem('currentUser', JSON.stringify(user));
          this.currentUserSubject.next(user);
          
          return { success: true, user };
        } else {
          return { success: false, message: 'Invalid email or password' };
        }
      })
    );
  }

  signup(credentials: SignupCredentials): Observable<{ success: boolean; message?: string; user?: User }> {
    // Simulate API call
    return of(null).pipe(
      delay(1000),
      map(() => {
        const user: User = {
          id: Math.random().toString(36).substr(2, 9),
          email: credentials.email,
          firstName: credentials.firstName,
          lastName: credentials.lastName,
          createdAt: new Date()
        };
        
        localStorage.setItem('currentUser', JSON.stringify(user));
        this.currentUserSubject.next(user);
        
        return { success: true, user };
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