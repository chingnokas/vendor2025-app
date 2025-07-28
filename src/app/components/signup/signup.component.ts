import { Component, OnInit } from '@angular/core';
import { CommonModule } from '@angular/common';
import { ReactiveFormsModule, FormBuilder, FormGroup, Validators, AbstractControl } from '@angular/forms';
import { Router, RouterModule } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-signup',
  standalone: true,
  imports: [CommonModule, ReactiveFormsModule, RouterModule],
  template: `
    <div class="auth-container">
      <div class="auth-card">
        <!-- Header -->
        <div class="auth-header">
          <h1 class="brand-text">Service<span class="brand-accent">Portal</span></h1>
          <h2 class="auth-title">Create Account</h2>
          <p class="auth-subtitle">Join thousands of satisfied customers</p>
        </div>

        <!-- Form -->
        <form [formGroup]="signupForm" (ngSubmit)="onSubmit()" class="auth-form">
          <!-- Name Fields -->
          <div class="name-grid">
            <div class="form-group">
              <label for="firstName" class="form-label">First Name</label>
              <input
                type="text"
                id="firstName"
                formControlName="firstName"
                class="form-input"
                [class.error]="isFieldInvalid('firstName')"
                placeholder="First name">
              <div *ngIf="isFieldInvalid('firstName')" class="error-message">
                <span *ngIf="signupForm.get('firstName')?.errors?.['required']">First name is required</span>
              </div>
            </div>

            <div class="form-group">
              <label for="lastName" class="form-label">Last Name</label>
              <input
                type="text"
                id="lastName"
                formControlName="lastName"
                class="form-input"
                [class.error]="isFieldInvalid('lastName')"
                placeholder="Last name">
              <div *ngIf="isFieldInvalid('lastName')" class="error-message">
                <span *ngIf="signupForm.get('lastName')?.errors?.['required']">Last name is required</span>
              </div>
            </div>
          </div>

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
              <span *ngIf="signupForm.get('email')?.errors?.['required']">Email is required</span>
              <span *ngIf="signupForm.get('email')?.errors?.['email']">Please enter a valid email</span>
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
              <span *ngIf="signupForm.get('password')?.errors?.['required']">Password is required</span>
              <span *ngIf="signupForm.get('password')?.errors?.['minlength']">Password must be at least 6 characters</span>
            </div>
          </div>

          <!-- Confirm Password Field -->
          <div class="form-group">
            <label for="confirmPassword" class="form-label">Confirm Password</label>
            <input
              type="password"
              id="confirmPassword"
              formControlName="confirmPassword"
              class="form-input"
              [class.error]="isFieldInvalid('confirmPassword')"
              placeholder="Confirm your password">
            <div *ngIf="isFieldInvalid('confirmPassword')" class="error-message">
              <span *ngIf="signupForm.get('confirmPassword')?.errors?.['required']">Please confirm your password</span>
              <span *ngIf="signupForm.get('confirmPassword')?.errors?.['passwordMismatch']">Passwords do not match</span>
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
            <span *ngIf="!isLoading">Create Account</span>
            <span *ngIf="isLoading">Creating Account...</span>
          </button>
        </form>

        <!-- Footer -->
        <div class="auth-footer">
          <p class="text-center">
            Already have an account? 
            <a routerLink="/login" class="auth-link">Sign in</a>
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
      max-width: 450px;
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

    .name-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1rem;
      margin-bottom: 1.5rem;
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

    @media (max-width: 480px) {
      .auth-card {
        padding: 2rem 1.5rem;
      }

      .name-grid {
        grid-template-columns: 1fr;
        gap: 0;
      }

      .back-home {
        top: 1rem;
        left: 1rem;
      }
    }
  `]
})
export class SignupComponent implements OnInit {
  signupForm!: FormGroup;
  isLoading = false;
  errorMessage = '';

  constructor(
    private fb: FormBuilder,
    private authService: AuthService,
    private router: Router
  ) {}

  ngOnInit(): void {
    this.signupForm = this.fb.group({
      firstName: ['', [Validators.required]],
      lastName: ['', [Validators.required]],
      email: ['', [Validators.required, Validators.email]],
      password: ['', [Validators.required, Validators.minLength(6)]],
      confirmPassword: ['', [Validators.required]]
    }, {
      validators: this.passwordMatchValidator
    });
  }

  passwordMatchValidator(control: AbstractControl): { [key: string]: boolean } | null {
    const password = control.get('password');
    const confirmPassword = control.get('confirmPassword');

    if (!password || !confirmPassword) {
      return null;
    }

    if (password.value !== confirmPassword.value) {
      confirmPassword.setErrors({ passwordMismatch: true });
      return { passwordMismatch: true };
    } else {
      const errors = confirmPassword.errors;
      if (errors) {
        delete errors['passwordMismatch'];
        if (Object.keys(errors).length === 0) {
          confirmPassword.setErrors(null);
        }
      }
    }

    return null;
  }

  isFieldInvalid(fieldName: string): boolean {
    const field = this.signupForm.get(fieldName);
    return !!(field && field.invalid && (field.dirty || field.touched));
  }

  onSubmit(): void {
    if (this.signupForm.valid) {
      this.isLoading = true;
      this.errorMessage = '';

      this.authService.signup(this.signupForm.value).subscribe({
        next: (result) => {
          this.isLoading = false;
          if (result.success) {
            this.router.navigate(['/']);
          } else {
            this.errorMessage = result.message || 'Signup failed';
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
    Object.keys(this.signupForm.controls).forEach(key => {
      const control = this.signupForm.get(key);
      control?.markAsTouched();
    });
  }
}