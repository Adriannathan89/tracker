import { Component, inject, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LucideX } from '@lucide/angular';
import { DiscordVerifyFormComponent } from './discord-verify-form.component';

@Component({
  selector: 'app-discord-verify-dialog',
  standalone: true,
  imports: [CommonModule, MatDialogModule, LucideX, DiscordVerifyFormComponent],
  styles: [`
    :host { display: block; }
    .dialog-container {
      width: 480px;
      background: var(--bw-surface);
      border-radius: 24px;
      overflow: hidden;
    }
    .dialog-header {
      background: var(--bw-ink);
      padding: 18px 22px;
      display: flex;
      align-items: center;
      justify-content: space-between;
    }
    .header-eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--bw-on-ink);
      opacity: 0.7;
    }
    .header-title {
      font-size: 18px;
      font-weight: 800;
      color: var(--bw-on-ink);
      margin: 2px 0 0;
    }
    .close-btn {
      all: unset;
      cursor: pointer;
      width: 30px;
      height: 30px;
      border-radius: 8px;
      color: var(--bw-on-ink);
      opacity: 0.75;
      display: flex;
      align-items: center;
      justify-content: center;
      transition: opacity 0.2s, background 0.2s;
    }
    .close-btn:hover {
      opacity: 1;
      background: rgba(255,255,255,0.1);
    }
    .dialog-body { padding: 22px 24px; }
    .dialog-footer {
      padding: 14px 22px 22px;
      display: flex;
      justify-content: space-between;
      gap: 10px;
    }
    .btn {
      border-radius: 12px;
      padding: 10px 16px;
      font-size: 13px;
      font-weight: 600;
      cursor: pointer;
      border: 1.5px solid var(--bw-border);
      background: transparent;
      color: var(--bw-ink-2);
    }
    .btn:hover { background: var(--bw-sunken); }
    .btn-primary {
      background: var(--bw-emerald);
      color: var(--bw-on-ink);
      border-color: var(--bw-emerald);
    }
  `],
  template: `
    <div class="dialog-container">
      <div class="dialog-header">
        <div>
          <div class="header-eyebrow">Verifikasi</div>
          <h2 class="header-title">Hubungkan Discord</h2>
        </div>
        <button class="close-btn" (click)="close()">
          <svg lucideX class="w-4 h-4"></svg>
        </button>
      </div>
      <div class="dialog-body">
        <app-discord-verify-form
          #form
          (verifiedEvent)="onVerified()"
          (expiredEvent)="onExpired()" />
      </div>
      <div class="dialog-footer">
        <button class="btn" (click)="close()">Batal</button>
        <button class="btn btn-primary" (click)="form.generateCode()">Generate code baru</button>
      </div>
    </div>
  `,
})
export class DiscordVerifyDialogComponent {
  @ViewChild('form') form!: DiscordVerifyFormComponent;

  private snackBar = inject(MatSnackBar);

  constructor(public dialogRef: MatDialogRef<DiscordVerifyDialogComponent>) {}

  close() {
    this.dialogRef.close();
  }

  onVerified() {
    this.snackBar.open('Discord terhubung ✓', 'Tutup', { duration: 2500 });
    this.dialogRef.close('verified');
  }

  onExpired() {
    // Form already shows expired state — user can click "Generate code baru"
  }
}
