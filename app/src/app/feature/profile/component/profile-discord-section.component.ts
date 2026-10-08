import { Component, EventEmitter, Input, Output, inject, signal } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatDialog } from '@angular/material/dialog';
import { MatBottomSheet } from '@angular/material/bottom-sheet';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ProfileService } from '../../../core/service/user/profile.service';
import { Profile } from '../../../core/model/profile.model';
import { DiscordVerifyDialogComponent } from '../ui/discord-verify-dialog.component';
import { DiscordVerifySheetComponent } from '../ui/discord-verify-sheet.component';

@Component({
  selector: 'app-profile-discord-section',
  standalone: true,
  imports: [CommonModule],
  styles: [`
    .card {
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 16px;
      padding: 20px 24px;
    }
    .header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 12px;
    }
    .title {
      font-size: 15px;
      font-weight: 800;
      color: var(--bw-ink);
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .connected-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      font-size: 12px;
      font-weight: 700;
      color: var(--bw-green);
    }
    .dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--bw-green);
    }
    .username {
      font-size: 18px;
      font-weight: 700;
      color: var(--bw-ink);
      margin-bottom: 18px;
    }
    .explain {
      font-size: 13px;
      color: var(--bw-ink-3);
      line-height: 1.5;
      margin-bottom: 16px;
    }
    .btn {
      border-radius: 12px;
      padding: 11px 18px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      border: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.15s;
    }
    .btn-primary {
      background: var(--bw-emerald);
      color: var(--bw-on-ink);
    }
    .btn-primary:hover { opacity: 0.9; }
    .btn-danger {
      background: transparent;
      color: var(--bw-red);
      border: 1.5px solid var(--bw-red-soft);
    }
    .btn-danger:hover { background: var(--bw-red-soft); }
    .toggle-row {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 12px 0;
      border-top: 1px solid var(--bw-border);
    }
    .toggle-row:first-of-type { border-top: none; padding-top: 6px; }
    .toggle-label {
      font-size: 13px;
      color: var(--bw-ink-2);
    }
    .switch {
      position: relative;
      width: 44px;
      height: 24px;
      border-radius: 999px;
      background: var(--bw-sunken);
      border: 1px solid var(--bw-border);
      cursor: pointer;
      transition: background 0.2s;
    }
    .switch.on {
      background: var(--bw-emerald);
      border-color: var(--bw-emerald);
    }
    .switch .thumb {
      position: absolute;
      top: 2px;
      left: 2px;
      width: 18px;
      height: 18px;
      border-radius: 50%;
      background: var(--bw-surface);
      transition: transform 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }
    .switch.on .thumb { transform: translateX(20px); }
    .toggles-block { margin: 6px 0 16px; }
  `],
  template: `
    <div class="card">
      <div class="header">
        <div class="title">
          <span>💬</span>
          <span>Discord</span>
        </div>
        @if (profile.discord.connected) {
          <span class="connected-badge"><span class="dot"></span>Terhubung</span>
        }
      </div>

      @if (!profile.discord.connected) {
        <div class="explain">
          Hubungkan akun Discord kamu untuk dapat notifikasi tiap commit transaksi
          dan laporan keuangan mingguan otomatis setiap Sabtu malam.
        </div>
        <button class="btn btn-primary" (click)="onConnect()">
          Hubungkan Discord
        </button>
      } @else {
        <div class="username">{{ '@' + profile.discord.username }}</div>

        <div class="toggles-block">
          <div class="toggle-row">
            <span class="toggle-label">Notifikasi setiap transaksi</span>
            <div class="switch" [class.on]="profile.discord.commitNotifEnabled"
                 (click)="toggleNotif('commit', !profile.discord.commitNotifEnabled)">
              <div class="thumb"></div>
            </div>
          </div>
          <div class="toggle-row">
            <span class="toggle-label">Laporan mingguan (Sabtu)</span>
            <div class="switch" [class.on]="profile.discord.weeklyNotifEnabled"
                 (click)="toggleNotif('weekly', !profile.discord.weeklyNotifEnabled)">
              <div class="thumb"></div>
            </div>
          </div>
        </div>

        <button class="btn btn-danger" (click)="onDisconnect()" [disabled]="working()">
          Putuskan Discord
        </button>
      }
    </div>
  `,
})
export class ProfileDiscordSectionComponent {
  @Input() profile!: Profile;
  @Output() profileChanged = new EventEmitter<void>();

  private dialog = inject(MatDialog);
  private bottomSheet = inject(MatBottomSheet);
  private snackBar = inject(MatSnackBar);
  private profileService = inject(ProfileService);

  working = signal(false);

  onConnect() {
    const isMobile = window.innerWidth < 768;
    if (isMobile) {
      const ref = this.bottomSheet.open(DiscordVerifySheetComponent, {
        panelClass: 'discord-verify-sheet-panel',
        hasBackdrop: true,
      });
      ref.afterDismissed().subscribe(result => {
        if (result === 'verified') this.profileChanged.emit();
      });
    } else {
      const ref = this.dialog.open(DiscordVerifyDialogComponent, {
        panelClass: 'discord-verify-dialog-panel',
        width: '480px',
      });
      ref.afterClosed().subscribe(result => {
        if (result === 'verified') this.profileChanged.emit();
      });
    }
  }

  async onDisconnect() {
    if (this.working()) return;
    this.working.set(true);
    try {
      await this.profileService.disconnectDiscord();
      this.snackBar.open('Discord diputus.', 'Tutup', { duration: 2500 });
      this.profileChanged.emit();
    } catch {
      this.snackBar.open('Gagal memutus Discord. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.working.set(false);
    }
  }

  async toggleNotif(type: 'commit' | 'weekly', enabled: boolean) {
    if (this.working()) return;
    this.working.set(true);
    try {
      await this.profileService.updateNotifSettings(type, enabled);
      this.profileChanged.emit();
    } catch {
      this.snackBar.open('Gagal mengubah pengaturan notifikasi.', 'Tutup', { duration: 3000 });
    } finally {
      this.working.set(false);
    }
  }
}
