import { Component, Inject, signal, inject, ViewChild, HostListener } from '@angular/core';
import { CommonModule } from '@angular/common';
import { MAT_DIALOG_DATA, MatDialogRef, MatDialogModule } from '@angular/material/dialog';
import { MatSnackBar } from '@angular/material/snack-bar';
import { LucideX, LucideCheck, LucideTrash2 } from '@lucide/angular';
import { CommitRecordFormComponent } from './commit-record-form.component';
import { UserRecordsService } from '../../../../core/service/user/user-records.service';
import { Record } from '../../../../core/model/record.model';

export type CommitRecordDialogData = Record;

@Component({
  selector: 'app-commit-record-dialog',
  standalone: true,
  imports: [
    CommonModule,
    MatDialogModule,
    LucideX,
    LucideCheck,
    LucideTrash2,
    CommitRecordFormComponent,
  ],
  styles: [`
    :host { display: block; }

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
      0%   { opacity: 0; transform: scale(0.90) translateY(-12px); }
      100% { opacity: 1; transform: scale(1)    translateY(0); }
    }

    .dialog-header {
      background: var(--bw-ink);
      padding: 22px 24px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 14px;
    }

    .header-left { display: flex; flex-direction: column; flex: 1; }

    .header-eyebrow {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--bw-on-ink);
      opacity: 0.6;
      margin-bottom: 2px;
    }

    .header-title {
      font-size: 18px;
      font-weight: 800;
      letter-spacing: -0.02em;
      margin: 0;
      color: var(--bw-on-ink);
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

    .close-btn:hover { background: var(--bw-on-ink-dim); }

    .dialog-body {
      flex: 1;
      overflow-y: auto;
      padding: 24px;
    }

    .dialog-footer {
      background: var(--bw-elevated);
      border-top: 1px solid var(--bw-border);
      padding: 14px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
    }

    .footer-hint {
      font-size: 11px;
      color: var(--bw-ink-3);
      flex: 1;
    }

    .kbd {
      display: inline-block;
      padding: 2px 5px;
      border-radius: 4px;
      background: var(--bw-surface);
      border: 1px solid var(--bw-border);
      font-family: 'JetBrains Mono', monospace;
      font-size: 10px;
      margin: 0 2px;
    }

    .footer-buttons {
      display: flex;
      gap: 8px;
      align-items: center;
    }

    .btn {
      padding: 10px 16px;
      border-radius: 12px;
      font-size: 13px;
      font-weight: 600;
      border: none;
      cursor: pointer;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
      outline: none;
    }

    .btn:active:not(:disabled) { transform: scale(0.97); }

    .btn-delete {
      background: transparent;
      color: var(--bw-red);
      border: 1.5px solid var(--bw-red-soft);
    }

    .btn-delete:hover { background: var(--bw-red-soft); }

    .btn-cancel {
      background: transparent;
      color: var(--bw-ink-2);
      border: 1.5px solid var(--bw-border);
    }

    .btn-cancel:hover { background: var(--bw-sunken); border-color: var(--bw-ink-2); }

    .btn-primary {
      background: var(--bw-emerald);
      color: var(--bw-on-ink);
      padding: 10px 20px;
    }

    .btn-primary:not(:disabled):hover {
      opacity: 0.9;
      transform: translateY(-1px);
      box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
    }

    .btn-primary:disabled { opacity: 0.45; cursor: not-allowed; }
  `],
  template: `
    <div class="dialog-container">
      <div class="dialog-header">
        <div class="header-left">
          <div class="header-eyebrow">Konfirmasi transaksi</div>
          <h2 class="header-title">Tinjau & konfirmasi</h2>
        </div>
        <button class="close-btn" (click)="dialogRef.close()">
          <svg lucideX class="w-4 h-4"></svg>
        </button>
      </div>

      <div class="dialog-body">
        <app-commit-record-form [record]="data" #formComponent />
      </div>

      <div class="dialog-footer">
        <div class="footer-hint">
          <span class="kbd">⌘ ↵</span> konfirmasi &nbsp;·&nbsp; <span class="kbd">Esc</span> tutup
        </div>
        <div class="footer-buttons">
          <button type="button" class="btn btn-delete"
                  [disabled]="submitting()"
                  (click)="confirmDelete()">
            <svg lucideTrash2 class="w-3.5 h-3.5"></svg>
            Hapus
          </button>
          <button type="button" class="btn btn-cancel" (click)="dialogRef.close()">
            Batal
          </button>
          <button type="button" class="btn btn-primary"
                  [disabled]="submitting()"
                  (click)="submit()">
            <svg lucideCheck class="w-4 h-4"></svg>
            {{ submitting() ? 'Menyimpan...' : 'Konfirmasi' }}
          </button>
        </div>
      </div>
    </div>
  `,
})
export class CommitRecordDialogComponent {
  @ViewChild('formComponent') form!: CommitRecordFormComponent;

  private recordsService = inject(UserRecordsService);
  private snackBar = inject(MatSnackBar);
  submitting = signal(false);

  constructor(
    public dialogRef: MatDialogRef<CommitRecordDialogComponent>,
    @Inject(MAT_DIALOG_DATA) public data: CommitRecordDialogData,
  ) {}

  @HostListener('window:keydown', ['$event'])
  onKeyDown(event: KeyboardEvent) {
    if ((event.metaKey || event.ctrlKey) && event.key === 'Enter') {
      event.preventDefault();
      if (!this.submitting()) this.submit();
    }
    if (event.key === 'Escape') {
      this.dialogRef.close();
    }
  }

  async submit() {
    this.submitting.set(true);
    try {
      const changed = this.form.getCategoryOrUndefinedWithSecondary();
      await this.recordsService.commitRecord(this.data.id, changed?.category, changed?.secondary);
      this.snackBar.open('Transaksi berhasil dikonfirmasi ✓', 'Tutup', { duration: 2500 });
      this.dialogRef.close('committed');
    } catch {
      this.snackBar.open('Gagal mengonfirmasi transaksi. Coba lagi.', 'Tutup', { duration: 3000 });
    } finally {
      this.submitting.set(false);
    }
  }

  confirmDelete() {
    const snackRef = this.snackBar.open('Hapus transaksi ini?', 'Ya, hapus', { duration: 5000 });
    snackRef.onAction().subscribe(() => this.doDelete());
  }

  private async doDelete() {
    this.submitting.set(true);
    try {
      await this.recordsService.deleteRecord(this.data.id);
      this.snackBar.open('Transaksi dihapus.', 'Tutup', { duration: 2000 });
      this.dialogRef.close('deleted');
    } catch {
      this.snackBar.open('Gagal menghapus transaksi.', 'Tutup', { duration: 3000 });
    } finally {
      this.submitting.set(false);
    }
  }
}
