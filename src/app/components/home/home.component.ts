import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { AuthService } from '../../services/auth.service';

@Component({
  selector: 'app-home',
  standalone: true,
  imports: [CommonModule],
  template: `
    <div class="home-container">
      <!-- Header -->
      <header class="header">
        <div class="container">
          <div class="nav-brand">
            <h1 class="brand-text">Service<span class="brand-accent">Portal</span></h1>
          </div>
          <nav class="nav-menu">
            <button 
              *ngIf="!authService.isAuthenticated()" 
              (click)="goToLogin()" 
              class="btn btn-secondary">
              Sign In
            </button>
            <button 
              *ngIf="authService.isAuthenticated()" 
              (click)="logout()" 
              class="btn btn-secondary">
              Logout
            </button>
          </nav>
        </div>
      </header>

      <!-- Main Content -->
      <main class="main-content">
        <div class="container">
          <div class="content-grid">
            <!-- Left Side - Information -->
            <div class="info-section">
              <div class="welcome-text">
                <h2 class="main-title">Connect with trusted service providers in your area</h2>
                <p class="subtitle">From plumbing to cleaning, find the right professional for your needs.</p>
              </div>

              <!-- Stats -->
              <div class="stats-grid">
                <div class="stat-card">
                  <div class="stat-number">500+</div>
                  <div class="stat-label">Verified Vendors</div>
                </div>
                <div class="stat-card">
                  <div class="stat-number">1000+</div>
                  <div class="stat-label">Happy Customers</div>
                </div>
              </div>

              <!-- Popular Services -->
              <div class="services-section">
                <h3 class="services-title">Popular Services</h3>
                <div class="services-tags">
                  <span class="service-tag">Plumbing</span>
                  <span class="service-tag">Cleaning</span>
                  <span class="service-tag">Electrical</span>
                  <span class="service-tag">Gardening</span>
                  <span class="service-tag">Painting</span>
                </div>
              </div>
            </div>

            <!-- Right Side - Login Form or User Dashboard -->
            <div class="form-section">
              <div *ngIf="!authService.isAuthenticated()" class="login-prompt">
                <div class="form-card">
                  <h3 class="form-title">Get Started</h3>
                  <p class="form-subtitle">Join thousands of satisfied customers</p>
                  <div class="button-group">
                    <button (click)="goToLogin()" class="btn btn-primary btn-full">Sign In</button>
                    <button (click)="goToSignup()" class="btn btn-secondary btn-full">Create Account</button>
                  </div>
                </div>
              </div>

              <div *ngIf="authService.isAuthenticated()" class="user-dashboard">
                <div class="form-card">
                  <h3 class="form-title">Welcome back!</h3>
                  <p class="form-subtitle">{{ getUserName() }}</p>
                  <div class="dashboard-actions">
                    <button class="btn btn-primary btn-full mb-4">Find Services</button>
                    <button class="btn btn-secondary btn-full">My Bookings</button>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </main>
    </div>
  `,
  styles: [`
    .home-container {
      min-height: 100vh;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    }

    .header {
      padding: 1rem 0;
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
    }

    .container {
      max-width: 1200px;
      margin: 0 auto;
      padding: 0 1rem;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .brand-text {
      font-size: 1.75rem;
      font-weight: 700;
      color: white;
      margin: 0;
    }

    .brand-accent {
      color: #fbbf24;
    }

    .main-content {
      padding: 3rem 0;
    }

    .content-grid {
      display: grid;
      grid-template-columns: 1fr 400px;
      gap: 3rem;
      align-items: start;
    }

    .info-section {
      color: white;
    }

    .main-title {
      font-size: 2.5rem;
      font-weight: 700;
      margin-bottom: 1rem;
      line-height: 1.2;
    }

    .subtitle {
      font-size: 1.2rem;
      margin-bottom: 3rem;
      opacity: 0.9;
    }

    .stats-grid {
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 1.5rem;
      margin-bottom: 3rem;
    }

    .stat-card {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      padding: 2rem;
      border-radius: 1rem;
      text-align: center;
      border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .stat-number {
      font-size: 2.5rem;
      font-weight: 700;
      color: #fbbf24;
      margin-bottom: 0.5rem;
    }

    .stat-label {
      font-size: 1rem;
      opacity: 0.9;
    }

    .services-section {
      background: rgba(255, 255, 255, 0.1);
      backdrop-filter: blur(10px);
      padding: 2rem;
      border-radius: 1rem;
      border: 1px solid rgba(255, 255, 255, 0.2);
    }

    .services-title {
      font-size: 1.25rem;
      font-weight: 600;
      margin-bottom: 1rem;
    }

    .services-tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.75rem;
    }

    .service-tag {
      background: rgba(255, 255, 255, 0.2);
      color: white;
      padding: 0.5rem 1rem;
      border-radius: 1.5rem;
      font-size: 0.875rem;
      font-weight: 500;
      cursor: pointer;
      transition: all 0.2s ease;
    }

    .service-tag:hover {
      background: rgba(255, 255, 255, 0.3);
      transform: translateY(-1px);
    }

    .form-section {
      position: sticky;
      top: 2rem;
    }

    .form-card {
      background: white;
      padding: 2rem;
      border-radius: 1rem;
      box-shadow: 0 10px 40px rgba(0, 0, 0, 0.1);
    }

    .form-title {
      font-size: 1.5rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: #1f2937;
    }

    .form-subtitle {
      color: #6b7280;
      margin-bottom: 2rem;
    }

    .button-group {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }

    .dashboard-actions {
      display: flex;
      flex-direction: column;
      gap: 1rem;
    }

    @media (max-width: 768px) {
      .content-grid {
        grid-template-columns: 1fr;
        gap: 2rem;
      }

      .main-title {
        font-size: 2rem;
      }

      .stats-grid {
        grid-template-columns: 1fr;
      }

      .form-section {
        position: static;
      }
    }
  `]
})
export class HomeComponent {
  constructor(
    public authService: AuthService,
    private router: Router
  ) {}

  goToLogin(): void {
    this.router.navigate(['/login']);
  }

  goToSignup(): void {
    this.router.navigate(['/signup']);
  }

  logout(): void {
    this.authService.logout();
  }

  getUserName(): string {
    const user = this.authService.currentUserValue;
    return user ? `${user.firstName} ${user.lastName}` : '';
  }
}