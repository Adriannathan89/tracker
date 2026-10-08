import { Component, OnInit, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Router } from '@angular/router';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ProfileService } from '../../core/service/user/profile.service';
import { Profile } from '../../core/model/profile.model';
import { ProfileBasicInfoComponent } from './component/profile-basic-info.component';
import { ProfileDiscordSectionComponent } from './component/profile-discord-section.component';

@Component({
  selector: 'app-profile-page',
  standalone: true,
  imports: [CommonModule, ProfileBasicInfoComponent, ProfileDiscordSectionComponent],
  styles: [`
    .container {
      padding: 24px 32px;
      max-width: 720px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      gap: 18px;
    }
    .page-title {
      font-size: 28px;
      font-weight: 900;
      letter-spacing: -0.04em;
      color: var(--bw-ink);
      margin: 8px 0 4px;
    }
    .loading {
      text-align: center;
      padding: 60px;
      color: var(--bw-ink-3);
    }
    @media (max-width: 767px) {
      .container { padding: 16px; }
      .page-title { font-size: 22px; }
    }
  `],
  template: `
    <div class="container">
      <h1 class="page-title">Profile</h1>
      @if (loading()) {
        <div class="loading">Memuat...</div>
      } @else if (profile()) {
        <app-profile-basic-info [profile]="profile()!" />
        <app-profile-discord-section
          [profile]="profile()!"
          (profileChanged)="loadProfile()" />
      }
    </div>
  `,
})
export class ProfilePage implements OnInit {
  private profileService = inject(ProfileService);
  private snackBar = inject(MatSnackBar);
  private router = inject(Router);

  profile = signal<Profile | null>(null);
  loading = signal(true);

  ngOnInit() {
    this.loadProfile();
  }

  async loadProfile() {
    this.loading.set(true);
    try {
      const p = await this.profileService.getProfile();
      this.profile.set(p);
    } catch {
      this.snackBar.open('Gagal memuat profile', 'Tutup', { duration: 2500 });
    } finally {
      this.loading.set(false);
    }
  }
}
