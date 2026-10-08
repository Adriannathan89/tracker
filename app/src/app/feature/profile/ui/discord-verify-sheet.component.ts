import { Component, inject, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MatBottomSheetRef, MatBottomSheetModule } from '@angular/material/bottom-sheet';
import { MatSnackBar } from '@angular/material/snack-bar';
import { DiscordVerifyFormComponent } from './discord-verify-form.component';

@Component({
  selector: 'app-discord-verify-sheet',
  standalone: true,
  imports: [CommonModule, MatBottomSheetModule, DiscordVerifyFormComponent],
  styles: [`
    :host { display: block; width: 100%; }
    .sheet-container {
      padding: 12px 16px 28px;
      display: flex;
      flex-direction: column;
      width: 100%;
      box-sizing: border-box;
    }
    .drag-handle {
      width: 36px;
      height: 4px;
      background: var(--bw-border-strong);
      border-radius: 2px;
      margin: 0 auto 14px;
    }
    .sheet-header {
      margin-bottom: 16px;
    }
    .header-eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--bw-ink-3);
      margin-bottom: 3px;
    }
    .header-title {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.03em;
      margin: 0;
      color: var(--bw-ink);
    }
    .sheet-footer {
      display: flex;
      gap: 8px;
      margin-top: 16px;
      padding-top: 16px;
      border-top: 1px solid var(--bw-border);
    }
    .btn {
      flex: 1;
      border-radius: 12px;
      padding: 12px 16px;
      font-size: 14px;
      font-weight: 600;
      cursor: pointer;
      border: 1.5px solid var(--bw-border);
      background: transparent;
      color: var(--bw-ink-2);
    }
    .btn-primary {
      background: var(--bw-emerald);
      color: var(--bw-on-ink);
      border-color: var(--bw-emerald);
    }
  `],
  template: `
    <div class="sheet-container">
      <div class="drag-handle"></div>
      <div class="sheet-header">
        <div class="header-eyebrow">Verifikasi</div>
        <h2 class="header-title">Hubungkan Discord</h2>
      </div>
      <app-discord-verify-form
        #form
        (verifiedEvent)="onVerified()"
        (expiredEvent)="onExpired()" />
      <div class="sheet-footer">
        <button class="btn" (click)="close()">Batal</button>
        <button class="btn btn-primary" (click)="form.generateCode()">Generate baru</button>
      </div>
    </div>
  `,
})
export class DiscordVerifySheetComponent {
  @ViewChild('form') form!: DiscordVerifyFormComponent;

  private snackBar = inject(MatSnackBar);

  constructor(public sheetRef: MatBottomSheetRef<DiscordVerifySheetComponent>) {}

  close() {
    this.sheetRef.dismiss();
  }

  onVerified() {
    this.snackBar.open('Discord terhubung ✓', 'Tutup', { duration: 2500 });
    this.sheetRef.dismiss('verified');
  }

  onExpired() {
    // Form shows expired state — user clicks "Generate baru"
  }
}
