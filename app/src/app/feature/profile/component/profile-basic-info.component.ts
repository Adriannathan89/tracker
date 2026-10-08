import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Profile } from '../../../core/model/profile.model';

@Component({
  selector: 'app-profile-basic-info',
  standalone: true,
  imports: [CommonModule],
  styles: [`
    .card {
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 16px;
      padding: 20px 24px;
      display: flex;
      align-items: center;
      gap: 16px;
    }
    .avatar {
      width: 56px;
      height: 56px;
      border-radius: 50%;
      background: var(--bw-ink);
      color: var(--bw-on-ink);
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 22px;
      font-weight: 800;
      flex-shrink: 0;
    }
    .username {
      font-size: 18px;
      font-weight: 800;
      color: var(--bw-ink);
      letter-spacing: -0.02em;
    }
    .meta {
      font-size: 12px;
      color: var(--bw-ink-3);
      margin-top: 3px;
    }
  `],
  template: `
    <div class="card">
      <div class="avatar">{{ initial() }}</div>
      <div>
        <div class="username">{{ profile.username }}</div>
        <div class="meta">Anggota tracker</div>
      </div>
    </div>
  `,
})
export class ProfileBasicInfoComponent {
  @Input() profile!: Profile;

  initial(): string {
    return (this.profile?.username ?? '?').charAt(0).toUpperCase();
  }
}
