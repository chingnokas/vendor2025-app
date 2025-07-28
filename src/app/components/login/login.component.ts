import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  template: `
    <div class="auth-container">
      <div class="auth-card">
        <!-- Header -->
        <div class="auth-header">
          <h1 class="brand-text">Service<span class="brand-accent">Portal</span></h1>
          <h2 class="auth-title">Sign in</h2>
          <p class="auth-subtitle">Enter your email and password to access your account</p>
        </div>

        <!-- Form -->
        <form [formGroup]="loginForm" (ngSubmit)="onSubmit()" class="auth-form">
          <!-- Email Field -->
          <div class="form-group">
            <label for="email" class="form-label">Email</label>
            <input
              type="email"
              id="email"
              formControlName="email"
              class="form-input"
              [class.error]="isFieldInvalid('email')"
              placeholder="Enter your email">
            <div *ngIf="isFieldInvalid('email')" class="error-message">
              <span *ngIf="loginForm.get('email')?.errors?.['required']">Email is required</span>
              <span *ngIf="loginForm.get('email')?.errors?.['email']">Please enter a valid email</span>
            </div>
          </div>

          <!-- Password Field -->
          <div class="form-group">
            <label for="password" class="form-label">Password</label>
            <input
              type="password"
              id="password"
              formControlName="password"
              class="form-input"
              [class.error]="isFieldInvalid('password')"
              placeholder="Enter your password">
            <div *ngIf="isFieldInvalid('password')" class="error-message">
              <span *ngIf="loginForm.get('password')?.errors?.['required']">Password is required</span>
            </div>
          </div>

          <!-- Error Message -->
          <div *ngIf="errorMessage" class="error-message mb-4">
            {{ errorMessage }}
          </div>

          <!-- Submit Button -->
          <button
            type="submit"
            class="btn btn-primary btn-full"
            [disabled]="isLoading">
            <span *ngIf="!isLoading">Sign in</span>
            <span *ngIf="isLoading">Signing in...</span>
          </button>

          <!-- Demo Credentials -->
          <div class="demo-info">
            <p class="text-sm text-center" style="color: #6b7280; margin-top: 1rem;">
              Demo credentials: demo&#64;example.com / password
            </p>
          </div>
        </form>

        <!-- Footer -->
        <div class="auth-footer">
          <p class="text-center">
            Don't have an account? 
            <a routerLink="/signup" class="auth-link">Sign up</a>
          </p>
        </div>
      </div>

      <!-- Back to Home -->
      <div class="back-home">
        <a routerLink="/" class="back-link">← Back to Home</a>
      </div>
    </div>
  `,
  styles: [`
    .auth-container {
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem 1rem;
      position: relative;
    }

    .auth-card {
      background: white;
      padding: 2.5rem;
      border-radius: 1rem;
      box-shadow: 0 20px 60px rgba(0, 0, 0, 0.1);
      width: 100%;
      max-width: 400px;
    }

    .auth-header {
      text-align: center;
      margin-bottom: 2rem;
    }

    .brand-text {
      font-size: 1.75rem;
      font-weight: 700;
      color: #1f2937;
      margin-bottom: 1.5rem;
    }

    .brand-accent {
      color: #8b5cf6;
    }

    .auth-title {
      font-size: 1.5rem;
      font-weight: 600;
      color: #1f2937;
      margin-bottom: 0.5rem;
    }

    .auth-subtitle {
      color: #6b7280;
      font-size: 0.875rem;
    }

    .auth-form {
      margin-bottom: 2rem;
    }

    .auth-footer {
      text-align: center;
    }

    .auth-link {
      color: #8b5cf6;
      text-decoration: none;
      font-weight: 500;
    }

    .auth-link:hover {
      text-decoration: underline;
    }

    .back-home {
      position: absolute;
      top: 2rem;
      left: 2rem;
    }

    .back-link {
      color: white;
      text-decoration: none;
      font-weight: 500;
      opacity: 0.9;
      transition: opacity 0.2s ease;
    }

    .back-link:hover {
      opacity: 1;
    }

    .demo-info {
      background: #f8fafc;
      padding: 1rem;
      border-radius: 0.5rem;
      margin-top: 1rem;
      border: 1px solid #e2e8f0;
    }

    @media (max-width: 480px) {
      .auth-card {
        padding: 2rem 1.5rem;
      }

      .back-home {
        top: 1rem;
        left: 1rem;
      }
    }
  `]
})
export class LoginComponent implements OnInit {
  loginForm!: FormGroup;
  isLoading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.loginForm = this.fb.group({
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required]]
    });
  }

  isFieldInvalid(fieldName: string): boolean {
    const field = this.loginForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  onSubmit(): void {
    if (this.loginForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';

      this.authService.login(this.loginForm.value).subscribe({
        next: (result) => {
          this.isLoading = false;
          if (result.success) {
            this.router.navigate(['/']);
          } else {
            this.errorMessage = result.message || 'Login failed';
          }
        },
        error: (error) => {
          this.isLoading = false;
          this.errorMessage = 'An error occurred. Please try again.';
        }
      });
    } else {
      this.markFormGroupTouched();
    }
  }

  private markFormGroupTouched(): void {
    Object.keys(this.loginForm.controls).forEach(key => {
      const control = this.loginForm.get(key);
      control?.markAsTouched();
    });
  }
}