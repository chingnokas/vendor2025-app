// 🚀 Frontend-Only CI/CD Pipeline Test - ARGOCD AUTO-PULL TEST
// This change will trigger GitHub Actions → Build Image → Update Helm → ArgoCD Auto-Pull
// Testing ArgoCD auto-pull functionality on Digital Ocean cluster
// Timestamp: $(date)
import { Component } from '@angular/core';
import { bootstrapApplication } from '@angular/platform-browser';
import { provideRouter } from '@angular/router';
import { importProvidersFrom } from '@angular/core';
import { ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';
import { RouterOutlet } from '@angular/router';

import { HomeComponent } from './app/components/home/home.component';
import { LoginComponent } from './app/components/login/login.component';
import { SignupComponent } from './app/components/signup/signup.component';

const routes = [
  { path: '', component: HomeComponent },
  { path: 'login', component: LoginComponent },
  { path: 'signup', component: SignupComponent },
  { path: '**', redirectTo: '' }
];

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule, RouterOutlet],
  template: `
    <router-outlet></router-outlet>
  `
})
export class App {}

bootstrapApplication(App, {
  providers: [
    provideRouter(routes),
    importProvidersFrom(ReactiveFormsModule)
  ]
});// GitOps pipeline test
