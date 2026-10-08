import { Component, Inject, signal, inject, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LucideX, LucideCheck } from '@lucide/angular';
import { AddDebtFormComponent } from './add-debt-form.component';
import { DebtService } from '../../../core/service/debt/debt.service';

export type AddDebtDialogData = {
  friendId: string;
  friendName: string;
  friendInitial: string;
};

@Component({
  selector: 'app-add-debt-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    LucideX,
    LucideCheck,
    AddDebtFormComponent,
  ],
  styles: [`
    :host {
      display: block;
    }

    .dialog-container {
      width: 540px;
      background: var(--bw-surface);
      border-radius: 24px;
      overflow: hidden;
      display: flex;
      flex-direction: column;
      max-height: 90vh;
      animation: dialog-pop-in 0.35s cubic-bezier(0.34, 1.56, 0.64, 1) forwards;
    }

    @keyframes dialog-pop-in {
      0% {
        opacity: 0;
        transform: scale(0.90) translateY(-12px);
      }
      100% {
        opacity: 1;
        transform: scale(1) translateY(0);
      }
    }

    .dialog-header {
      background: var(--bw-ink);
      color: var(--bw-on-ink);
      padding: 22px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
    }

    .header-left {
      display: flex;
      align-items: center;
      gap: 14px;
      flex: 1;
    }

    .avatar {
      width: 44px;
      height: 44px;
      border-radius: 50%;
      background: var(--bw-emerald);
      color: var(--bw-on-ink);
      display: flex;
      align-items: center;
      justify-content: center;
      font-weight: 800;
      font-size: 16px;
      flex-shrink: 0;
    }

    .header-text {
      flex: 1;
    }

    .header-eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--bw-on-ink);
      opacity: 0.75;
      margin-bottom: 2px;
    }

    .header-title {
      font-size: 18px;
      font-weight: 800;
      letter-spacing: -0.02em;
      margin: 0;
    }

    .close-btn {
      all: unset;
      cursor: pointer;
      width: 36px;
      height: 36px;
      border-radius: 12px;
      background: var(--bw-on-ink-ghost);
      color: var(--bw-on-ink);
      display: flex;
      align-items: center;
      justify-content: center;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      flex-shrink: 0;
    }

    .close-btn:hover {
      background: var(--bw-on-ink-dim);
    }

    .dialog-body {
      flex: 1;
      overflow-y: auto;
      padding: 24px;
    }

    .dialog-footer {
      background: var(--bw-elevated);
      border-top: 1px solid var(--bw-border);
      padding: 16px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 16px;
    }

    .footer-hint {
      font-size: 12px;
      color: var(--bw-ink-3);
      flex: 1;
    }

    .kbd {
      display: inline-block;
      padding: 2px 6px;
      border-radius: 4px;
      background: var(--bw-surface);
      border: 1px solid var(--bw-border);
      font-family: 'JetBrains Mono', monospace;
      font-size: 11px;
      margin: 0 3px;
    }

    .footer-buttons {
      display: flex;
      gap: 8px;
    }

    .btn {
      padding: 12px 18px;
      border-radius: 12px;
      font-size: 14px;
      font-weight: 600;
      border: none;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 8px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      outline: none;
    }

    .btn:active {
      transform: scale(0.98);
    }

    .btn-cancel {
      background: transparent;
      color: var(--bw-ink-2);
      border: 1.5px solid var(--bw-border);
    }

    .btn-cancel:hover {
      background: var(--bw-sunken);
      border-color: var(--bw-ink-2);
    }

    .btn-primary {
      background: var(--bw-ink);
      color: var(--bw-on-ink);
    }

    .btn-primary:not(:disabled) {
      cursor: pointer;
    }

    .btn-primary:not(:disabled):hover {
      opacity: 0.92;
      transform: translateY(-2px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .btn-primary:disabled {
      opacity: 0.5;
      cursor: not-allowed;
    }
  `],
  template: `
    <div class="dialog-container">
      <!-- Header -->
      <div class="dialog-header">
        <div class="header-left">
          <div class="avatar">{{ data.friendInitial }}</div>
          <div class="header-text">
            <div class="header-eyebrow">Tambah hutang ke</div>
            <h2 class="header-title">{{ data.friendName }}</h2>
          </div>
        </div>
        <button class="close-btn" (click)="dialogRef.close()">
          <svg lucideX class="w-4 h-4"></svg>
        </button>
      </div>

      <!-- Body -->
      <div class="dialog-body">
        <app-add-debt-form [friendName]="data.friendName" #formComponent></app-add-debt-form>
      </div>

      <!-- Footer -->
      <div class="dialog-footer">
        <div class="footer-hint">
          Ketik angka untuk nominal • <span class="kbd">⌘ ↵</span> simpan • <span class="kbd">Esc</span> tutup
        </div>
        <div class="footer-buttons">
          <button type="button" class="btn btn-cancel" (click)="dialogRef.close()">
            Batal
          </button>
          <button
            type="button"
            class="btn btn-primary"
            [disabled]="!canSubmit() || submitting()"
            (click)="submit()">
            <svg lucideCheck class="w-4 h-4"></svg>
            {{ submitting() ? 'Menyimpan...' : 'Simpan hutang' }}
          </button>
        </div>
      </div>
    </div>
  `,
})
export class AddDebtDialogComponent {
  @ViewChild(AddDebtFormComponent) form!: AddDebtFormComponent;

  private debtService = inject(DebtService);
  private snackBar = inject(MatSnackBar);
  submitting = signal(false);

  canSubmit = () => this.form?.amount() > 0;

  constructor(
    public dialogRef: MatDialogRef<AddDebtDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: AddDebtDialogData,
  ) {}

  @HostListener('window:keydown', ['$event'])
  onKeyDown(event: KeyboardEvent) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault();
      if (this.canSubmit()) {
        this.submit();
      }
    }

    if (event.key === 'Escape') {
      this.dialogRef.close();
    }
  }

  async submit() {
    if (!this.form || this.form.amount() === 0) {
      this.snackBar.open('Masukkan nominal terlebih dahulu', 'Tutup', { duration: 2000 });
      return;
    }

    if (this.form.direction() === 'debt') {
      this.snackBar.open('Fitur "aku hutang ke dia" masih dalam pengembangan.', 'Tutup', { duration: 3000 });
      return;
    }

    this.submitting.set(true);
    try {
      await this.debtService.createDebt(
        this.form.amount(),
        this.form.description(),
        this.data.friendId,
      );
      this.snackBar.open(`Hutang berhasil dicatat ke ${this.data.friendName}`, 'Tutup', { duration: 2500 });
      this.dialogRef.close('success');
    } catch {
      this.snackBar.open('Gagal menyimpan hutang. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.submitting.set(false);
    }
  }
}
