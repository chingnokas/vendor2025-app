import { Injectable } from '@angular/core';
import { CanActivate, Router } from '@angular/router';
import { AuthService } from './auth.service';

@Injectable({
  providedIn: 'root'
})
export class RoleGuard implements CanActivate {
  constructor(
    private authService: AuthService,
    private router: Router
  ) {}

  canActivate(): boolean {
    const role = this.authService.getRole();
    const requiredRole = this.router.url.includes('vendor') ? 'vendor' : 'user';
    
    if (role !== requiredRole) {
      this.router.navigate(['/login']);
      return false;
    }
    return true;
  }
}
