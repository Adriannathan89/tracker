import { Component, EventEmitter, Output, OnInit, OnDestroy, inject, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatSnackBar } from '@angular/material/snack-bar';
import { ProfileService } from '../../../core/service/user/profile.service';
import { DiscordVerifyData } from '../../../core/model/profile.model';

@Component({
  selector: 'app-discord-verify-form',
  standalone: true,
  imports: [CommonModule],
  styles: [`
    :host { display: block; }

    .install-block {
      background: var(--bw-sunken);
      border: 1px solid var(--bw-border);
      border-radius: 12px;
      padding: 14px;
      margin-bottom: 18px;
      text-align: center;
    }
    .install-label {
      font-size: 11px;
      color: var(--bw-ink-3);
      margin-bottom: 6px;
    }
    .install-link {
      font-size: 13px;
      font-weight: 700;
      color: var(--bw-emerald);
      text-decoration: none;
      display: inline-flex;
      align-items: center;
      gap: 6px;
    }
    .install-link:hover { text-decoration: underline; }

    .instruction {
      font-size: 13px;
      color: var(--bw-ink-2);
      text-align: center;
      margin-bottom: 12px;
      line-height: 1.5;
    }

    .code-box {
      background: var(--bw-sunken);
      border: 2px dashed var(--bw-border-strong);
      border-radius: 14px;
      padding: 16px;
      margin-bottom: 14px;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 12px;
    }
    .code-text {
      font-family: 'JetBrains Mono', monospace;
      font-size: 22px;
      font-weight: 700;
      letter-spacing: 0.05em;
      color: var(--bw-ink);
    }
    .copy-btn {
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 8px;
      padding: 6px 10px;
      font-size: 12px;
      cursor: pointer;
      color: var(--bw-ink-2);
      transition: all 0.15s;
    }
    .copy-btn:hover {
      background: var(--bw-surface);
      border-color: var(--bw-border-strong);
    }

    .countdown {
      text-align: center;
      font-size: 13px;
      color: var(--bw-ink-3);
      margin-bottom: 12px;
    }
    .countdown.expired { color: var(--bw-red); font-weight: 700; }

    .status {
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      font-size: 13px;
      color: var(--bw-ink-3);
      padding: 10px;
      background: var(--bw-sunken);
      border-radius: 10px;
      margin-bottom: 10px;
    }
    .spinner {
      width: 14px;
      height: 14px;
      border: 2px solid var(--bw-border);
      border-top-color: var(--bw-emerald);
      border-radius: 50%;
      animation: spin 0.8s linear infinite;
    }
    @keyframes spin {
      to { transform: rotate(360deg); }
    }
  `],
  template: `
    @if (loading()) {
      <div style="text-align:center; padding:40px; color: var(--bw-ink-3);">Memuat...</div>
    } @else if (data()) {
      <div class="install-block">
        <div class="install-label">Belum punya bot di Discord?</div>
        <a class="install-link" [href]="data()!.installUrl" target="_blank" rel="noopener">
          🔗 Install {{ '@' + data()!.botUsername }}
        </a>
      </div>

      <div class="instruction">
        DM bot <strong>{{ '@' + data()!.botUsername }}</strong> dan kirim command:
      </div>

      <div class="code-box">
        <span class="code-text">/verify {{ data()!.code }}</span>
        <button class="copy-btn" (click)="copyCommand()">📋 Salin</button>
      </div>

      <div class="countdown" [class.expired]="isExpired()">
        @if (!isExpired()) {
          ⏱️ Code expired dalam {{ formattedCountdown() }}
        } @else {
          ❌ Code expired. Generate baru.
        }
      </div>

      @if (!isExpired() && !isVerified()) {
        <div class="status">
          <div class="spinner"></div>
          <span>Menunggu verifikasi dari bot...</span>
        </div>
      }
    }
  `,
})
export class DiscordVerifyFormComponent implements OnInit, OnDestroy {
  @Output() verifiedEvent = new EventEmitter<void>();
  @Output() expiredEvent = new EventEmitter<void>();

  private profileService = inject(ProfileService);
  private snackBar = inject(MatSnackBar);
  private pollInterval: number | null = null;
  private countdownInterval: number | null = null;

  loading = signal(true);
  data = signal<DiscordVerifyData | null>(null);
  isVerified = signal(false);
  now = signal(Date.now());

  readonly secondsLeft = computed(() => {
    const d = this.data();
    if (!d) return 0;
    const exp = new Date(d.expiresAt).getTime();
    return Math.max(0, Math.floor((exp - this.now()) / 1000));
  });
  readonly isExpired = computed(() => this.data() !== null && this.secondsLeft() === 0);
  readonly formattedCountdown = computed(() => {
    const s = this.secondsLeft();
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
  });

  async ngOnInit() {
    await this.generateCode();
  }

  ngOnDestroy() {
    this.stopPolling();
    this.stopCountdown();
  }

  async generateCode() {
    this.loading.set(true);
    this.isVerified.set(false);
    this.stopPolling();
    this.stopCountdown();
    try {
      const d = await this.profileService.generateDiscordCode();
      this.data.set(d);
      this.startCountdown();
      this.startPolling();
    } catch {
      this.snackBar.open('Gagal generate code. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.loading.set(false);
    }
  }

  private startCountdown() {
    this.now.set(Date.now());
    this.countdownInterval = window.setInterval(() => {
      this.now.set(Date.now());
      if (this.isExpired()) {
        this.stopPolling();
        this.stopCountdown();
        this.expiredEvent.emit();
      }
    }, 1000);
  }

  private stopCountdown() {
    if (this.countdownInterval !== null) {
      clearInterval(this.countdownInterval);
      this.countdownInterval = null;
    }
  }

  private startPolling() {
    this.pollInterval = window.setInterval(async () => {
      try {
        const status = await this.profileService.getDiscordStatus();
        if (status.verified) {
          this.isVerified.set(true);
          this.stopPolling();
          this.stopCountdown();
          this.verifiedEvent.emit();
        }
      } catch {
        // network blip — ignore
      }
    }, 3000);
  }

  private stopPolling() {
    if (this.pollInterval !== null) {
      clearInterval(this.pollInterval);
      this.pollInterval = null;
    }
  }

  copyCommand() {
    const d = this.data();
    if (!d) return;
    const text = `/verify ${d.code}`;
    navigator.clipboard.writeText(text).then(() => {
      this.snackBar.open('Tersalin', 'Tutup', { duration: 1500 });
    });
  }
}
